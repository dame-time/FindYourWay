#include "ESPNowTransmitter.h"

ESPNowTransmitter::ESPNowTransmitter(int receiverNumber)
{
    Serial.begin(115200);

    // Set device as a Wi-Fi Station
    WiFi.mode(WIFI_STA);

    // Init ESP-NOW
    if (esp_now_init() != ESP_OK)
    {
        Serial.println("++++Error initializing ESP-NOW");
        // return;
    }
    else
    {
        Serial.println("ESP-NOW initialized");
    }

    // Register send callback
    esp_now_register_send_cb(ESPNowTransmitter::onDataSent);

    // Set the receiver address
    switch (receiverNumber)
    {
    case 1:
        macAddressToByteArray(receiverAddress1, peerMac);
        break;
    case 2:
        macAddressToByteArray(receiverAddress2, peerMac);
        break;
    case 3:
        macAddressToByteArray(receiverAddress3, peerMac);
        break;
    default:
        macAddressToByteArray(receiverAddress1, peerMac);
        break;
    }

    // Set the peer information
    peerInfo = {};
    peerInfo.ifidx = WIFI_IF_STA;
    peerInfo.channel = 0;
    peerInfo.encrypt = false;
    memcpy(peerInfo.peer_addr, peerMac, 6);

    Serial.println("Peer Info: " + String((const char*)peerInfo.peer_addr));                     

    if (esp_now_add_peer(&peerInfo) != ESP_OK)
    {
        Serial.println("+++Failed to add peer");
        // return;
    }
    else
    {
        Serial.println("Peer added");
    }
}

void ESPNowTransmitter::macAddressToByteArray(const String &macStr, uint8_t *macArr)
{
    sscanf(macStr.c_str(), "%hhx:%hhx:%hhx:%hhx:%hhx:%hhx",
           &macArr[0], &macArr[1], &macArr[2], &macArr[3], &macArr[4], &macArr[5]);
}

void ESPNowTransmitter::onDataSent(const uint8_t *mac_addr, esp_now_send_status_t status)
{
    Serial.print("Last Packet Send Status: ");
    if (status == ESP_NOW_SEND_SUCCESS)
    {
        Serial.println("Delivery success");
    }
    else
    {
        Serial.println("Delivery fail");
    }
}

void ESPNowTransmitter::sendMessage(int numStrings, ...)
{
    va_list args;
    va_start(args, numStrings);

    String totalMessage = "";
    for (int i = 0; i < numStrings; i++)
    {
        const char *str = va_arg(args, const char *);

        if (i + 1 < numStrings)
            totalMessage += String(str) + "-";
        else
            totalMessage += String(str);
    }
    va_end(args);

    if (totalMessage.length() >= 250)
    {
        // Handle message size exceeding the ESP-NOW limit
        return;
    }

    message msg;
    totalMessage.getBytes((unsigned char *)msg.data, totalMessage.length() + 1); // Cast to unsigned char*

    // Send the message using ESP-NOW
    esp_err_t result = esp_now_send(peerMac, (const uint8_t *)msg.data, totalMessage.length() + 1); // Cast to const uint8_t*
    if (result == ESP_OK)
    {
        Serial.println("Message sent");
    }
    else
    {
        Serial.println("Error sending message");
        Serial.println("+++++++++++++++++++++++++++++++" + String(esp_err_to_name(result)) + "----------------------------");
    }
}