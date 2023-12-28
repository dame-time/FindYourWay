#include <BLECallbacks.h>
#include <BLETransmitter.h>

void BLECallbacks::onConnect()
{
    Serial.println("BLE device connected");
}

void BLECallbacks::onDisconnect()
{
    Serial.println("BLE device disconnected");
}

void BLECallbacks::onWrite(BLECharacteristic *pCharacteristic)
{
    std::string rxValue = pCharacteristic->getValue();
    String receivedHexString = "";
    for (int i = 0; i < rxValue.length(); i++)
    {
        char buffer[3];
        sprintf(buffer, "%02x", (unsigned char)rxValue[i]);
        receivedHexString += buffer;
    }

    Serial.println(receivedHexString);
}