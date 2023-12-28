#pragma once

#include <Arduino.h>

#include <esp_now.h>
#include <WiFi.h>
#include <stdarg.h>

static String receiverAddress1 = String("DC:54:75:D0:0F:24");
static String receiverAddress2 = String("DC:54:75:D0:16:24");
static String receiverAddress3 = String("F4:12:FA:6D:D0:08");

class ESPNowTransmitter
{
    private:
        typedef struct message
        {
            uint8_t* data[250];
        } message;

        esp_now_peer_info_t peerInfo;
        uint8_t peerMac[6];

        static void onDataSent(const uint8_t *mac_addr, esp_now_send_status_t status);

        void macAddressToByteArray(const String &macStr, uint8_t *macArr);

    public:
        ESPNowTransmitter(int receiverNumber);

        void sendMessage(int numberOfStrings, ...);
};