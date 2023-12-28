#pragma once

#include <NimBLEDevice.h>
#include <Arduino.h>

#include <queue>

class BLEReceiver
{
    public:
        BLEReceiver();

        void connectToBLEServer();

        void addMessage(const char *message);
        String getMessage();
        bool hasAnyMessages();

        bool isConnectedToBLEServer() const
        {
            return isConnected;
        }

    private:
        NimBLEClient *pClient = nullptr;
        NimBLERemoteCharacteristic *pRemoteCharacteristic = nullptr;
        bool isConnected = false;
        std::queue<String> messageQueue;
};