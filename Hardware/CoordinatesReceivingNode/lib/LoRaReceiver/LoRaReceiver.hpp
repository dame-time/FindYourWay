#pragma once

#include "LoRaWan_APP.h"
#include "Arduino.h"

class LoRaReceiver
{
    private:
        RadioEvents_t RadioEvents;
        static LoRaReceiver* instance;

        bool rxDone;
        
        LoRaReceiver();

    public:
        static LoRaReceiver* getInstance();
        
        void receive();
        
        static void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr);
        static void OnRxTimeout(void);
};
