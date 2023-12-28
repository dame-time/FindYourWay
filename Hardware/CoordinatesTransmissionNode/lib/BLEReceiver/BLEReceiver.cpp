#include <BLEReceiver.h>

#include <Device.h>
#include <BLEClientCB.h>

#include <string>

BLEReceiver::BLEReceiver()
{
    NimBLEDevice::init(std::string(Device::getInstance()->getUUID().c_str()));
    pClient = NimBLEDevice::createClient();
    pClient->setClientCallbacks(new BLEClientCB(), false);
}

void BLEReceiver::connectToBLEServer()
{
    auto serverAddress = Device::getInstance()->getBLEPairedUUID().serverAddress;
    auto characteristicUUID = Device::getInstance()->getBLEPairedUUID().characteristicUUID;
    auto serviceUUID = Device::getInstance()->getBLEPairedUUID().serviceUUID;

    std::string serverAddressStr(serverAddress);
    std::string characteristicUUIDStr(characteristicUUID);
    std::string serviceUUIDStr(serviceUUID);

    Serial.println("Connecting to BLE Server: " + String(serverAddress));

    // Try to connect to the remote BLE server
    if (!pClient->connect(BLEAddress(serverAddressStr)))
    {
        Serial.println("Failed to connect to the server, retrying...");
        delay(1000); // Delay before retrying
        return;
    }

    Serial.println("Connected to the BLE server");

    // Obtain a reference to the service on the BLE server
    NimBLERemoteService *pRemoteService = pClient->getService(serviceUUIDStr);
    if (pRemoteService == nullptr)
    {
        Serial.println("Failed to find the service");
        pClient->disconnect();
        return;
    }

    // Obtain a reference to the characteristic on the BLE server
    pRemoteCharacteristic = pRemoteService->getCharacteristic(characteristicUUIDStr);
    if (pRemoteCharacteristic == nullptr)
    {
        Serial.println("Failed to find the characteristic");
        pClient->disconnect();
        return;
    }

    Serial.println("Found the characteristic");

    // Check if the characteristic has notifications enabled
    if (pRemoteCharacteristic->canNotify())
    {
        pRemoteCharacteristic->subscribe(true, [&](NimBLERemoteCharacteristic *pBLERemoteCharacteristic,
                                                  uint8_t *pData, size_t length, bool isNotify)
                                        {
                                            String receivedData = "";
                                            for (size_t i = 0; i < length; ++i)
                                                receivedData += (char)pData[i];

                                            messageQueue.push(receivedData);
                                            // Serial.println("Notification received: " + receivedData); 
                                        });
        Serial.println("Subscribed to notifications");
    }

    isConnected = true;
    Serial.println("Connected to BLE Server!!");
}

void BLEReceiver::addMessage(const char *message)
{
    messageQueue.push(String(message));
}

String BLEReceiver::getMessage()
{
    if (!messageQueue.empty())
    {
        String message = messageQueue.front();
        messageQueue.pop();
        return message;
    }
    return "";
}

bool BLEReceiver::hasAnyMessages()
{
    return !messageQueue.empty();
}
