#include <BLEServer.h>

#include <Arduino.h>

class BLECallbacks : public BLECharacteristicCallbacks
{
    private:
        BLEServer* pServer;

    public:
        BLECallbacks(BLEServer *server) : pServer(server) {}

        void onConnect();
        void onDisconnect();

        void onWrite(BLECharacteristic *pCharacteristic);
};