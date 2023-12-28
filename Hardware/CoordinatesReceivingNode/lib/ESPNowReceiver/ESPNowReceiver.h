#pragma once

#include <esp_now.h>
#include <WiFi.h>

class ESPNowReceiver {
    private:
        static void onDataReceived(const uint8_t *mac, const uint8_t *incomingData, int len);

    public:
        ESPNowReceiver();
};
