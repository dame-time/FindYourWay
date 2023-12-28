#pragma once

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#include <Arduino.h>

class BLETransmitter 
{
    private:
        BLEServer *pServer;
        BLEService *pService;
        BLECharacteristic *pCharacteristic;
        BLEAdvertising *pAdvertising;

        static BLETransmitter* instance;

        void handleConnection();

        BLETransmitter();

    public:
        static BLETransmitter* getInstance();

        void sendMessage(int numberOfStrings, ...);
};
