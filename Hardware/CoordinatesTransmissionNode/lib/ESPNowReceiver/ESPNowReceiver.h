#pragma once

#include <esp_now.h>
#include <WiFi.h>
#include <FreeRTOS.h>

#include <vector>

class ESPNowReceiver {
    private:
        static ESPNowReceiver* instance;

        SemaphoreHandle_t mutex;
        std::vector<String> receivedMessages;

        static void onDataReceived(const uint8_t *mac, const uint8_t *incomingData, int len);

    public:
        ESPNowReceiver();

        std::vector<String> getReceivedMessages();
};
