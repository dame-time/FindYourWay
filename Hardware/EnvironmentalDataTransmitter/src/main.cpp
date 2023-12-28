#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char *ssid = "casa paolillo";
const char *password = "willer99";

void setup()
{
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");

  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RX, TX);
}

void loop()
{
  if (Serial2.available())
  {
    String data = Serial2.readString();

    Serial.print("Received: ");
    Serial.println(data);

    StaticJsonDocument<200> jsonDoc;
    jsonDoc["data"] = data;

    String jsonString;
    serializeJson(jsonDoc, jsonString);

    HTTPClient http;
    http.begin("https://xgvq7ndbh5da4vhvrjqa4cnwsm0tyqzt.lambda-url.eu-west-2.on.aws/");
    http.addHeader("Content-Type", "application/json");
    int httpResponseCode = http.POST(jsonString);

    if (httpResponseCode > 0)
    {
      Serial.print("HTTP Response code: ");
      Serial.println(httpResponseCode);
    }
    else
    {
      Serial.println("Error sending HTTP request");
    }

    http.end();
  }

  Serial.print(Serial2.available());
  Serial.println();
}
