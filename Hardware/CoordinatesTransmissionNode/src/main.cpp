#include <BLEReceiver.h>
#include <Display.h>
#include <LoRaPeer.h>
#include <Device.h>
#include <MQTTClient.h>

BLEReceiver* bleReceiver;
MQTTClient* mqttClient;
// LoRaDevice::LoRaPeer* loraPeer;

const UUIDType DEVICE_NUMBER = UUIDType::DEVICE_003;

void setup() {
  Device::getInstance()->setUUID(DEVICE_NUMBER);
  // loraPeer = new LoRaDevice::LoRaPeer();

  Serial.begin(115200);

  *GUI::Display::getInstance() += Device::getInstance()->getUUID() + "\n";

  mqttClient = new MQTTClient();
  bleReceiver = new BLEReceiver();

  bleReceiver->connectToBLEServer();
}

void loop()
{
  static unsigned long lastRun = 0;
  unsigned long currentMillis = millis();

  if (currentMillis - lastRun >= 500)
  {
    lastRun = currentMillis;

    while (bleReceiver->hasAnyMessages())
    {
      auto message = bleReceiver->getMessage();

      if (message != "")
      {
        Serial.println("Publishing to: " + Device::getInstance()->getUUID());
        Serial.println("Message: " + message);
        mqttClient->publish("esp32/data/" + Device::getInstance()->getUUID(), message);
      }
    }
  }

  mqttClient->loop();
}
