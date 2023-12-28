#include <MQTTClient.h>
#include <Device.h>

MQTTClient::MQTTClient()
{
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.println("Connecting to WiFi...");
    }
    Serial.println("Connected to WiFi");


    espClient = new WiFiClientSecure();

    espClient->setCACert(aws_root_ca);
    espClient->setCertificate(aws_certificate);
    espClient->setPrivateKey(aws_private_key);

    client = new PubSubClient(*espClient);
    
    client->setServer(mqttServer, mqttPort);

    while (!client->connected())
    {
        Serial.println("Connecting to MQTT...");

        if ((mqttUser == nullptr || String(mqttUser).length() == 0) &&
            (mqttPassword == nullptr || String(mqttPassword).length() == 0))
        {
            if (client->connect(Device::getInstance()->getUUID().c_str()))
                Serial.println("Connected to MQTT");
            else
                Serial.println("Failed connection to MQTT");
        }
        else
        {
            if (client->connect(Device::getInstance()->getUUID().c_str(), mqttUser, mqttPassword))
                Serial.println("Connected to MQTT");
            else
                Serial.println("Failed connection to MQTT");
        }

        if (!client->connected())
        {
            Serial.print("Failed with state ");
            Serial.println(client->state());
            delay(2000);
            // break;
        }
    }
}

void MQTTClient::publish(String topic, String message)
{
    client->publish(topic.c_str(), message.c_str());
}

void MQTTClient::loop()
{
    client->loop();
}