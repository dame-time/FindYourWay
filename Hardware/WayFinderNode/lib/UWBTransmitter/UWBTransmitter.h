#pragma once

#include "dw3000.h"
#include "SPI.h"

// #include <ESPNowTransmitter.h>
#include <BLETransmitter.h>

#include <chrono>

extern SPISettings _fastSPI;

#define PIN_RST 27
#define PIN_IRQ 34
#define PIN_SS 4

#define TX_ANT_DLY 16385
#define RX_ANT_DLY 16385
#define ALL_MSG_COMMON_LEN 10
#define ALL_MSG_SN_IDX 2
#define RESP_MSG_POLL_RX_TS_IDX 17
#define RESP_MSG_RESP_TX_TS_IDX 21
#define RESP_MSG_TS_LEN 4
#define POLL_RX_TO_RESP_TX_DLY_UUS 650

#define RX_BUFFER_SIZE 50

static dwt_config_t config = {
    5,                /* Channel number. */
    DWT_PLEN_128,     /* Preamble length. Used in TX only. */
    DWT_PAC8,         /* Preamble acquisition chunk size. Used in RX only. */
    9,                /* TX preamble code. Used in TX only. */
    9,                /* RX preamble code. Used in RX only. */
    1,                /* 0 to use standard 8 symbol SFD, 1 to use non-standard 8 symbol, 2 for non-standard 16 symbol SFD and 3 for 4z 8 symbol SDF type */
    DWT_BR_6M8,       /* Data rate. */
    DWT_PHRMODE_STD,  /* PHY header mode. */
    DWT_PHRRATE_STD,  /* PHY header rate. */
    (129 + 8 - 8),    /* SFD timeout (preamble length + 1 + SFD length - PAC size). Used in RX only. */
    DWT_STS_MODE_OFF, /* STS disabled */
    DWT_STS_LEN_64,   /* STS length see allowed values in Enum dwt_sts_lengths_e */
    DWT_PDOA_M0       /* PDOA mode off */
};

static uint8_t rx_poll_msg[] = {0x41, 0x88, 0, 0xCA, 0xDE, 'W', 'A', 'V', 'E', 0xE0, 0, 0};
static uint8_t tx_resp_msg[] = {0x41, 0x88, 0, 0xCA, 0xDE, 'U', 'W', 'B', '_', 'D', 'A', 'M', 'E', '_', 'X', 'X', 'X', 0xE1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
static uint8_t frame_seq_nb = 0;
static uint8_t rx_buffer[RX_BUFFER_SIZE];
static uint8_t rx_buffer_cpy[RX_BUFFER_SIZE];
static uint32_t status_reg = 0;
static uint64_t poll_rx_ts;
static uint64_t resp_tx_ts;

extern dwt_txconfig_t txconfig_options;

class UWBTransmitter
{
    private:
        const char* ID;

        bool checkACK = false;

        String anchor;
        String distance;
        String name;
        String TTS;

        // ESPNowTransmitter* transmitter;

        uint8_t* stringToByte(const char *text);
        String decodeBytesIntoString(uint8_t *rxData, uint32_t dataLength);

    public:
        UWBTransmitter(const char* identifier);

        void listenToIncomingMessages();
        void answerToIncomingMessages();
};