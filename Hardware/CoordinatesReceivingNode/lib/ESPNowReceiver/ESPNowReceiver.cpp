#include "ESPNowReceiver.h"

#include <Display.h>

ESPNowReceiver::ESPNowReceiver()
{
    WiFi.mode(WIFI_STA);
    if (esp_now_init() != ESP_OK)
    {
        Serial.println("Error initializing ESP-NOW");
        return;
    }

    String macAddress = WiFi.macAddress();
    Serial.print("MAC Address: ");
    Serial.println(macAddress);

    GUI::Display::getInstance() += "MAC Address: \n" + macAddress + "\n";

    // Register for a callback function that will be called when data is received.
    esp_now_register_recv_cb(ESPNowReceiver::onDataReceived);
}

void ESPNowReceiver::onDataReceived(const uint8_t *mac, const uint8_t *incomingData, int len)
{
    Serial.print("Received message from: ");
    for (int i = 0; i < 6; i++)
    {
        Serial.printf("%02X", mac[i]);
        if (i < 5)
            Serial.print(":");
    }

    GUI::Display::getInstance().clear();

    GUI::Display::getInstance() += "Data received: \n";
    String dataString = "";
    Serial.print(" Data: ");
    for (int i = 0; i < len; i++)
    {
        if ((i % 6) == 0)
            dataString += "\n";

        dataString += String((char)incomingData[i]);
        Serial.print((char)incomingData[i]);
    }
    
    GUI::Display::getInstance() += dataString;
    Serial.println();
}
