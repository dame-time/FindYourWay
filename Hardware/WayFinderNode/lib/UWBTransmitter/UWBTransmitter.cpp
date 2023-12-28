#include "UWBTransmitter.h"

#include <Device.h>

UWBTransmitter::UWBTransmitter(const char *identifier) : ID(identifier)
{
    UART_init();

    _fastSPI = SPISettings(16000000L, MSBFIRST, SPI_MODE0);

    spiBegin(PIN_IRQ, PIN_RST);
    spiSelect(PIN_SS);

    delay(2); // Time needed for DW3000 to start up (transition from INIT_RC to IDLE_RC, or could wait for SPIRDY event)

    while (!dwt_checkidlerc()) // Need to make sure DW IC is in IDLE_RC before proceeding
    {
        UART_puts("IDLE FAILED\r\n");
        while (1)
            ;
    }

    if (dwt_initialise(DWT_DW_INIT) == DWT_ERROR)
    {
        UART_puts("INIT FAILED\r\n");
        while (1)
            ;
    }

    // Enabling LEDs here for debug so that for each TX the D1 LED will flash on DW3000 red eval-shield boards.
    dwt_setleds(DWT_LEDS_ENABLE | DWT_LEDS_INIT_BLINK);

    /* Configure DW IC. See NOTE 6 below. */
    if (dwt_configure(&config)) // if the dwt_configure returns DWT_ERROR either the PLL or RX calibration has failed the host should reset the device
    {
        UART_puts("CONFIG FAILED\r\n");
        while (1)
            ;
    }

    /* Configure the TX spectrum parameters (power, PG delay and PG count) */
    dwt_configuretxrf(&txconfig_options);

    /* Apply default antenna delay value. See NOTE 2 below. */
    dwt_setrxantennadelay(RX_ANT_DLY);
    dwt_settxantennadelay(TX_ANT_DLY);

    /* Next can enable TX/RX states output on GPIOs 5 and 6 to help debug, and also TX/RX LEDs
     * Note, in real low power applications the LEDs should not be used. */
    dwt_setlnapamode(DWT_LNA_ENABLE | DWT_PA_ENABLE);

    tx_resp_msg[14] = (uint8_t)ID[9];
    tx_resp_msg[15] = (uint8_t)ID[10];
    tx_resp_msg[16] = (uint8_t)ID[11];

    // transmitter = espNowTransmitter;

    // Serial.print("tx_response_message: ");

    // for(int i = 0; i < 28; i++)
    //     Serial.print((char)tx_resp_msg[i]);

    anchor = "";
    distance = "";
    name = "";
    TTS = "";

    Serial.println("Range TX");
    Serial.println("Setup over........");
}

uint8_t* UWBTransmitter::stringToByte(const char *text)
{
    uint8_t *txDataBytes = (uint8_t *)text;
    uint16_t txDataLength = strlen(text) + 1;

    // Check if txDataLength exceeds the buffer limit
    if (txDataLength > 127 - 2)
        return nullptr;

    return txDataBytes;
}

String UWBTransmitter::decodeBytesIntoString(uint8_t *rxData, uint32_t dataLength)
{
    if (dataLength > 0)
        rxData[dataLength - 1] = '\0';

    char *receivedString = (char *)rxData;

    // Serial.println(receivedString);

    return String(receivedString);
}

void UWBTransmitter::listenToIncomingMessages()
{
    /* Activate reception immediately. */
    dwt_rxenable(DWT_START_RX_IMMEDIATE);

    /* Poll for reception of a frame or error/timeout. See NOTE 6 below. */
    while (!((status_reg = dwt_read32bitreg(SYS_STATUS_ID)) & (SYS_STATUS_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_ERR)))
    {
    };
}

void UWBTransmitter::answerToIncomingMessages()
{
    if (status_reg & SYS_STATUS_RXFCG_BIT_MASK)
    {
        uint32_t frame_len;

        /* Clear good RX frame event in the DW IC status register. */
        dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_RXFCG_BIT_MASK);

        /* A frame has been received, read it into the local buffer. */
        frame_len = dwt_read32bitreg(RX_FINFO_ID) & RXFLEN_MASK;
        if (frame_len <= sizeof(rx_buffer))
        {
            // TODO: Parse the received message, extract the Distance, the name to check and the sleep time
            dwt_readrxdata(rx_buffer, frame_len, 0);
            bool check = strstr((const char *)rx_buffer, Device::getInstance()->getUUID().c_str()) != nullptr;

            /* Check that the frame is a poll sent by "SS TWR initiator" example.
             * As the sequence number field of the frame is not relevant, it is cleared to simplify the validation of the frame. */
            // rx_buffer[ALL_MSG_SN_IDX] = 0;
            if (check)
            {
                uint32_t resp_tx_time;
                int ret;

                /* Retrieve poll reception timestamp. */
                poll_rx_ts = get_rx_timestamp_u64();

                uint32_t currentTime = dwt_readsystimestamphi32();
                /* Compute response message transmission time. See NOTE 7 below. */
                resp_tx_time = (poll_rx_ts + (POLL_RX_TO_RESP_TX_DLY_UUS * UUS_TO_DWT_TIME)) >> 8;
                dwt_setdelayedtrxtime(resp_tx_time);

                /* Response TX timestamp is the transmission time we programmed plus the antenna delay. */
                resp_tx_ts = (((uint64_t)(resp_tx_time & 0xFFFFFFFEUL)) << 8) + TX_ANT_DLY;

                /* Write all timestamps in the final message. See NOTE 8 below. */
                resp_msg_set_ts(&tx_resp_msg[RESP_MSG_POLL_RX_TS_IDX], poll_rx_ts);
                resp_msg_set_ts(&tx_resp_msg[RESP_MSG_RESP_TX_TS_IDX], resp_tx_ts);

                /* Write and send the response message. See NOTE 9 below. */
                tx_resp_msg[ALL_MSG_SN_IDX] = frame_seq_nb;
                dwt_writetxdata(sizeof(tx_resp_msg), tx_resp_msg, 0); /* Zero offset in TX buffer. */
                dwt_writetxfctrl(sizeof(tx_resp_msg), 0, 1);          /* Zero offset in TX buffer, ranging. */

                ret = dwt_starttx(DWT_START_TX_DELAYED);

                /* If dwt_starttx() returns an error, abandon this ranging exchange and proceed to the next one. See NOTE 10 below. */
                if (ret == DWT_SUCCESS)
                {
                    Serial.println((const char *)tx_resp_msg);
                    checkACK = strstr((const char *)rx_buffer, "ACK") != nullptr;

                    if (checkACK)
                    {
                        String receivedMsg = decodeBytesIntoString(rx_buffer, frame_len);
                        Serial.println(receivedMsg);
                        anchor = receivedMsg.substring(5, 9);
                        String parsedMsg = receivedMsg.substring(10);

                        int i = 0;
                        for (; i < parsedMsg.length(); i++)
                        {
                            distance += parsedMsg[i];
                            String test = parsedMsg.substring(i + 1, i + 4);
                            if (test == "UWB" || test == "NUL")
                                break;
                        }

                        name = parsedMsg.substring(i + 1, i + 13);
                        TTS = parsedMsg.substring(i + 13);

                        Serial.println("Anchor: " + anchor);
                        Serial.println("Distance: " + distance);
                        Serial.println("Name: " + name);
                        Serial.println("TTS: " + TTS);
                    }

                    /* Poll DW IC until TX frame sent event set. See NOTE 6 below. */
                    while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS_BIT_MASK))
                    {
                    };

                    /* Clear TXFRS event. */
                    dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS_BIT_MASK);

                    /* Increment frame sequence number after transmission of the poll message (modulo 256). */
                    frame_seq_nb++;

                    if (checkACK)
                    {
                        char *ACKMessage = "ACK";
                        auto ACKMessageInt = stringToByte(ACKMessage);

                        dwt_writetxdata(sizeof(ACKMessageInt), ACKMessageInt, 0); /* Zero offset in TX buffer. */
                        dwt_writetxfctrl(sizeof(ACKMessageInt), 0, 1);            /* Zero offset in TX buffer, ranging. */

                        ret = dwt_starttx(DWT_START_TX_IMMEDIATE);
                        checkACK = false;

                        if (ret == DWT_SUCCESS)
                        {
                            /* Poll DW IC until TX frame sent event set. See NOTE 6 below. */
                            while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS_BIT_MASK))
                            {
                            };

                            /* Clear TXFRS event. */
                            dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS_BIT_MASK);

                            /* Increment frame sequence number after transmission of the poll message (modulo 256). */
                            frame_seq_nb++;

                            // Serial.println("Sent ACK!");

                            // transmitter->sendMessage(4, anchor, distance, name, TTS);
                            BLETransmitter::getInstance()->sendMessage(4, anchor, distance, name, TTS);

                            anchor = "";
                            distance = "";
                            name = "";
                            TTS = "";
                        }

                        // Sleep(TTS.toDouble()); // TODO: Check if this is useful
                    }
                }
                else
                {
                    // Handle error in transmission start
                    Serial.println("Failed to start delayed transmission");
                }
            }
        }
    }
    else
    {
        /* Clear RX error events in the DW IC status register. */
        dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_ALL_RX_ERR);
    }
}