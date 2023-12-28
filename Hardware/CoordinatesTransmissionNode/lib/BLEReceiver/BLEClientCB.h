#pragma once

#include <NimBLEDevice.h>

class BLEClientCB : public NimBLEClientCallbacks 
{
    public:
        void onConnect(NimBLEClient* pClient) override;
        void onDisconnect(NimBLEClient* pClient) override;

    // private:
        // BLEReceiver* m_bleReceiver;
};