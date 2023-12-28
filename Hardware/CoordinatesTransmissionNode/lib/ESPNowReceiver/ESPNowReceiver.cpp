#include "ESPNowReceiver.h"

#include <Display.h>

ESPNowReceiver* ESPNowReceiver::instance = nullptr;

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

    *GUI::Display::getInstance() += "MAC Address: \n" + macAddress + "\n";

    mutex = xSemaphoreCreateMutex();

    instance = this;

    // Register for a callback function that will be called when data is received.
    esp_now_register_recv_cb(ESPNowReceiver::onDataReceived);
}

void ESPNowReceiver::onDataReceived(const uint8_t *mac, const uint8_t *incomingData, int len)
{
    // Serial.print("Received message from: ");
    // for (int i = 0; i < 6; i++)
    // {
    //     Serial.printf("%02X", mac[i]);
    //     if (i < 5)
    //         Serial.print(":");
    // }

    // GUI::Display::getInstance().clear();

    // GUI::Display::getInstance() += "Data on ESP-NOW received!\n";
    String dataString = "";
    // Serial.print(" Data: ");
    for (int i = 0; i < len; i++)
    {
        dataString += String((char)incomingData[i]);
        // Serial.print((char)incomingData[i]);
    }

    int dividers = 0;
    String msg = "";
    for (int i = 0; i < dataString.length(); i++)
    {
        if (dataString[i] == '-')
            ++dividers;

        if (dividers > 0 && dividers < 3 && dataString[i] != '-')
            msg += dataString[i];

        if (dividers == 2 && dataString[i] == '-')
            msg += dataString[i];

        if (dividers >= 3)
            break;
    }

    Serial.println("Received message: " + msg);

    if (xSemaphoreTake(instance->mutex, portMAX_DELAY))
    {
        // Serial.println("Taking mutex for inserting!");
        instance->receivedMessages.push_back(msg);
        xSemaphoreGive(instance->mutex);
    }
}

std::vector<String> ESPNowReceiver::getReceivedMessages()
{
    std::vector<String> messages;

    if (xSemaphoreTake(instance->mutex, portMAX_DELAY))
    {
        // Serial.println("Taking mutex for the copy!");

        messages = std::vector<String>(receivedMessages);

        // for(auto &message : messages)
        //     Serial.println("Message: " + message);

        receivedMessages.clear();

        xSemaphoreGive(instance->mutex);
    }

    return messages;
}
