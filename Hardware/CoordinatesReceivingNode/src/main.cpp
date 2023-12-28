#include <LoRaPeer.h>
#include <Display.h>

LoRaDevice::LoRaPeer* loraPeer;

void setup()
{
  Serial.begin(115200);

  loraPeer = new LoRaDevice::LoRaPeer();

  GUI::Display &display = GUI::Display::getInstance();

  display += "LoRa Receiver...\n";
}

void loop()
{
  loraPeer->loop();
}