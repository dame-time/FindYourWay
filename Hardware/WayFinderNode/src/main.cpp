#include <UWBTransmitter.h>
// #include <ESPNowTransmitter.h>
#include <BLETransmitter.h>
#include <Device.h>

UWBTransmitter* uwbTransmitter;
// ESPNowTransmitter* espNowTransmitter;

const UUIDType DEVICE_NUMBER = UUIDType::DEVICE_003;

// TODO: Switch to BLE communication
void setup()
{
  Serial.begin(115200);

  Device::getInstance()->setUUID(DEVICE_NUMBER);

  BLETransmitter::getInstance();
  uwbTransmitter = new UWBTransmitter(Device::getInstance()->getUUID().c_str());
}

void loop()
{
  uwbTransmitter->listenToIncomingMessages();
  uwbTransmitter->answerToIncomingMessages();
}