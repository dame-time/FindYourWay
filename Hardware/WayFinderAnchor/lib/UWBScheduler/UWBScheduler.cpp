#include "UWBScheduler.h"

double UWBScheduler::tof;
double UWBScheduler::distance;
String UWBScheduler::lastDeviceMeasured;
String UWBScheduler::lastDeviceTTS;

UWBScheduler::UWBScheduler()
{
    UART_init();

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

    /* Set expected response's delay and timeout. See NOTE 1 and 5 below.
     * As this example only handles one incoming frame with always the same delay and timeout, those values can be set here once for all. */
    dwt_setrxaftertxdelay(POLL_TX_TO_RESP_RX_DLY_UUS);
    dwt_setrxtimeout(RESP_RX_TIMEOUT_UUS);

    /* Next can enable TX/RX states output on GPIOs 5 and 6 to help debug, and also TX/RX LEDs
     * Note, in real low power applications the LEDs should not be used. */
    dwt_setlnapamode(DWT_LNA_ENABLE | DWT_PA_ENABLE);

    for (int i = 12; i < MAX_MSG_LEN; i++)
        tx_poll_msg[i] = 0;

    Serial.println("Range RX");
    Serial.println("Setup over........");

    currentDeviceIndex = 0;
    isACKMessage = false;

    updatePollMessage();

    randomSeed(analogRead(0));
}

void UWBScheduler::moveToNextDevice()
{
    if (currentDeviceIndex + 1 >= devices.size())
        Sleep(500);
        
    currentDeviceIndex = (currentDeviceIndex + 1) % devices.size();
}

void UWBScheduler::addDevice(const UWBDevice &device)
{
    this->devices.push_back(device);
}

void UWBScheduler::updatePollMessage()
{
    if (isACKMessage)
        buildACKMessage();
    else
        buildRequestMessage();
}

void UWBScheduler::buildACKMessage()
{
    char distanceStr[20];
    snprintf(distanceStr, sizeof(distanceStr), "DIST:%3.2f", distance);

    tx_poll_msg[INITIAL_MSG_LEN] = '\0';

    const char* ACK = "ACK";

    // Calculate the total length of the new message
    int totalLength = INITIAL_MSG_LEN + strlen(distanceStr) + lastDeviceMeasured.length() + lastDeviceTTS.length() + strlen(ACK);
    if (totalLength >= MAX_MSG_LEN)
        totalLength = MAX_MSG_LEN - 1; // Ensure we don't exceed MAX_MSG_LEN

    // Append the distance string to the end of the initial message
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN), distanceStr, strlen(distanceStr));
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN + strlen(distanceStr)), lastDeviceMeasured.c_str(), totalLength - INITIAL_MSG_LEN - strlen(distanceStr));
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN + strlen(distanceStr) + lastDeviceMeasured.length()), lastDeviceTTS.c_str(), totalLength - INITIAL_MSG_LEN - strlen(distanceStr) - lastDeviceMeasured.length());
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN + strlen(distanceStr) + lastDeviceMeasured.length() + lastDeviceTTS.length()), ACK, totalLength - INITIAL_MSG_LEN - strlen(distanceStr) - lastDeviceMeasured.length() - lastDeviceTTS.length());

    tx_poll_msg[totalLength] = '\0';

    isACKMessage = false;

    moveToNextDevice();
    scheduleCommunication();

    Serial.println("ACK message: " + String((char *)tx_poll_msg));
}

void UWBScheduler::buildRequestMessage()
{
    char distanceStr[20];
    snprintf(distanceStr, sizeof(distanceStr), "DIST:%3.2f", distance);

    tx_poll_msg[INITIAL_MSG_LEN] = '\0';

    // Calculate the total length of the new message
    int totalLength = INITIAL_MSG_LEN + strlen(distanceStr) + lastDeviceMeasured.length() + lastDeviceTTS.length();
    if (totalLength >= MAX_MSG_LEN)
        totalLength = MAX_MSG_LEN - 1; // Ensure we don't exceed MAX_MSG_LEN

    // Append the distance string to the end of the initial message
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN), distanceStr, strlen(distanceStr));
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN + strlen(distanceStr)), lastDeviceMeasured.c_str(), totalLength - INITIAL_MSG_LEN - strlen(distanceStr));
    strncpy((char *)(tx_poll_msg + INITIAL_MSG_LEN + strlen(distanceStr) + lastDeviceMeasured.length()), lastDeviceTTS.c_str(), totalLength - INITIAL_MSG_LEN - strlen(distanceStr) - lastDeviceMeasured.length());

    tx_poll_msg[totalLength] = '\0';

    // Serial.println("Request message: " + String((char *)tx_poll_msg));
}

void UWBScheduler::startCommunication()
{
    updatePollMessage();

    /* Write frame data to DW IC and prepare transmission. See NOTE 7 below. */
    tx_poll_msg[ALL_MSG_SN_IDX] = frame_seq_nb;
    dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS_BIT_MASK);
    dwt_writetxdata(sizeof(tx_poll_msg), tx_poll_msg, 0); /* Zero offset in TX buffer. */
    dwt_writetxfctrl(sizeof(tx_poll_msg), 0, 1);          /* Zero offset in TX buffer, ranging. */

    /* Start transmission, indicating that a response is expected so that reception is enabled automatically after the frame is sent and the delay
     * set by dwt_setrxaftertxdelay() has elapsed. */
    dwt_starttx(DWT_START_TX_IMMEDIATE | DWT_RESPONSE_EXPECTED);

    /* We assume that the transmission is achieved correctly, poll for reception of a frame or error/timeout. See NOTE 8 below. */
    while (!((status_reg = dwt_read32bitreg(SYS_STATUS_ID)) & (SYS_STATUS_RXFCG_BIT_MASK | SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR)))
    {
    };

    /* Increment frame sequence number after transmission of the poll message (modulo 256). */
    frame_seq_nb++;
}

void UWBScheduler::processIncomingMessage()
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
            dwt_readrxdata(rx_buffer, frame_len, 0);
            String rx_buffer_str = String((const char*)rx_buffer);

            // Serial.println((const char *)rx_buffer);
            // Serial.println(rx_buffer_str.indexOf(lastDeviceMeasured) >= 0);

            /* Check that the frame is the expected response from the companion "SS TWR responder" example.
             * As the sequence number field of the frame is not relevant, it is cleared to simplify the validation of the frame. */
            rx_buffer[ALL_MSG_SN_IDX] = 0;
            if (strstr((const char*)rx_buffer, "ACK") == nullptr && rx_buffer_str.indexOf(lastDeviceMeasured) >= 0)
            {
                uint32_t poll_tx_ts, resp_rx_ts, poll_rx_ts, resp_tx_ts;
                int32_t rtd_init, rtd_resp;
                float clockOffsetRatio;

                /* Retrieve poll transmission and response reception timestamps. See NOTE 9 below. */
                poll_tx_ts = dwt_readtxtimestamplo32();
                resp_rx_ts = dwt_readrxtimestamplo32();

                /* Read carrier integrator value and calculate clock offset ratio. See NOTE 11 below. */
                clockOffsetRatio = ((float)dwt_readclockoffset()) / (uint32_t)(1 << 26);

                /* Get timestamps embedded in response message. */
                resp_msg_get_ts(&rx_buffer[RESP_MSG_POLL_RX_TS_IDX], &poll_rx_ts);
                resp_msg_get_ts(&rx_buffer[RESP_MSG_RESP_TX_TS_IDX], &resp_tx_ts);

                /* Compute time of flight and distance, using clock offset ratio to correct for differing local and remote clock rates */
                rtd_init = resp_rx_ts - poll_tx_ts;
                rtd_resp = resp_tx_ts - poll_rx_ts;

                tof = ((rtd_init - rtd_resp * (1 - clockOffsetRatio)) / 2.0) * DWT_TIME_UNITS;
                distance = tof * SPEED_OF_LIGHT;

                String device;
                for (int i = 5; i < 17; i++)
                    device += (char)rx_buffer[i];

                Serial.print("Device: ");
                Serial.println(device);

                double randomValue = random(0, 10001) / 100.0;
                double deviceTTL = 300 - ((distance * distance) / 2);
                deviceTTL = deviceTTL >= 30 ? deviceTTL : 30;
                deviceTTL += randomValue;
                lastDeviceTTS = String(deviceTTL, 1);

                /* Display computed distance on LCD. */
                snprintf(dist_str, sizeof(dist_str), "DIST: %3.2f m", distance);
                test_run_info((unsigned char *)dist_str);

                isACKMessage = true;
            }
        }
    }
    else
    {
        /* Clear RX error/timeout events in the DW IC status register. */
        dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR);
    }

    Sleep(RNG_DELAY_MS);
}

void UWBScheduler::scheduleCommunication()
{
    if (devices.empty())
        return;

    lastDeviceMeasured = devices[currentDeviceIndex].getId();
    distance = 0.0;
    lastDeviceTTS = "0";
}