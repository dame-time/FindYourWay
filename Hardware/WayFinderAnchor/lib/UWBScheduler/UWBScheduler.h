#pragma once

#include "UWBDevice.h"
#include "dw3000.h"

#include <vector>
#include <iostream>
#include <cstdlib>
#include <ctime>  

#define PIN_RST 27
#define PIN_IRQ 34
#define PIN_SS 4

#define RNG_DELAY_MS 50
#define TX_ANT_DLY 16385
#define RX_ANT_DLY 16385
#define ALL_MSG_COMMON_LEN 10
#define ALL_MSG_SN_IDX 2
#define RESP_MSG_POLL_RX_TS_IDX 17
#define RESP_MSG_RESP_TX_TS_IDX 21
#define RESP_MSG_TS_LEN 4
#define POLL_TX_TO_RESP_RX_DLY_UUS 240
#define RESP_RX_TIMEOUT_UUS 400

#define MAX_MSG_LEN 50
#define INITIAL_MSG_LEN 10

extern dwt_txconfig_t txconfig_options;

/* Default communication configuration. We use default non-STS DW mode. */
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

static uint8_t tx_poll_msg[MAX_MSG_LEN] = {0x41, 0x88, 0, 0xCA, 0xDE, 'W', 'A', 'V', 'E', 0xE0, 0, 0};
static uint8_t rx_resp_msg[] = {0x41, 0x88, 0, 0xCA, 0xDE, 'U', 'W', 'B', '_', 'D', 'A', 'M', 'E', '_', 'X', 'X', 'X', 0xE1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
static uint8_t frame_seq_nb = 0;
static uint8_t rx_buffer[40];
static uint32_t status_reg = 0;

// TODO: Start the comunication with one peer at a time, wait for the response (if timeout then go to the next one)
// when i get a response then contact the other peer, and so on and so forth
class UWBScheduler
{
    public:
        UWBScheduler();

        void addDevice(const UWBDevice &device);

        void startCommunication();
        void processIncomingMessage();
        void scheduleCommunication();

    private:
        std::vector<UWBDevice> devices;
        int currentDeviceIndex;

        bool isACKMessage;

        static double tof;
        static double distance;
        static String lastDeviceMeasured;
        static String lastDeviceTTS;

        void moveToNextDevice();
        void updatePollMessage();

        void buildACKMessage();
        void buildRequestMessage();
};
