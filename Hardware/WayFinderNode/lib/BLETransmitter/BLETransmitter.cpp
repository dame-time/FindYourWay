#include <BLETransmitter.h>

#include <BLECallbacks.h>
#include <Device.h>

BLETransmitter *BLETransmitter::instance = nullptr;

BLETransmitter::BLETransmitter()
{
    BLEDevice::init(Device::getInstance()->getUUID().c_str());
    this->pServer = BLEDevice::createServer();

    this->pService = this->pServer->createService(Device::getInstance()->getBLEPairedUUID().serviceUUID);

    pCharacteristic = pService->createCharacteristic(
        Device::getInstance()->getBLEPairedUUID().characteristicUUID,
        BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_WRITE |
            BLECharacteristic::PROPERTY_NOTIFY |
            BLECharacteristic::PROPERTY_INDICATE);

    BLEDescriptor *pDescr_1 = new BLEDescriptor((uint16_t)0x2901);
    pDescr_1->setValue("Testing descriptor");
    pCharacteristic->addDescriptor(pDescr_1);

    this->pCharacteristic->setCallbacks(new BLECallbacks(this->pServer));

    this->pService->start();

    pAdvertising = BLEDevice::getAdvertising();

    pAdvertising->addServiceUUID(Device::getInstance()->getBLEPairedUUID().serviceUUID);
    pAdvertising->setScanResponse(true);
    // pAdvertising->setMinPreferred(0x06);
    // pAdvertising->setMinPreferred(0x12);

    Serial.println("<<<<<<<<<<<<<<<<" + String(BLEDevice::getAddress().toString().c_str()) + ">>>>>>>>>>>>>>>>>>");

    BLEDevice::startAdvertising();
}

BLETransmitter *BLETransmitter::getInstance()
{
    if (instance == nullptr)
        instance = new BLETransmitter();

    return instance;
}

void BLETransmitter::sendMessage(int numberOfStrings, ...)
{
    // if (true)
    // {
        va_list args;
        va_start(args, numberOfStrings);

        for (int i = 0; i < numberOfStrings; i++)
        {
            String message = va_arg(args, char *);
            pCharacteristic->setValue(message.c_str());
            pCharacteristic->notify();

            Serial.println("Sending message: " + message);
        }

        va_end(args);
    // }
}