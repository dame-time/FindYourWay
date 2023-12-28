#include <BLEClientCB.h>

void BLEClientCB::onConnect(NimBLEClient *pClient)
{
    Serial.println("Connected to BLE Server");
}

void BLEClientCB::onDisconnect(NimBLEClient *pClient)
{
    Serial.println("Disconnected from BLE Server");
}