#include <DHT.h>
#include <Arduino.h>

#define DHTPIN D4
#define DHTTYPE DHT11     // DHT 11 sensor
#define PIRPIN D2

DHT dht(DHTPIN, DHTTYPE);

void setup()
{
    Serial.begin(9600);
    dht.begin();
    pinMode(PIRPIN, INPUT);
}

void loop()
{
    // Read temperature and humidity from DHT11
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    // Read motion state from PIR sensor
    int motionState = digitalRead(PIRPIN);

    // Print the data to the Serial monitor
    Serial.print("Humidity: ");
    Serial.print(humidity);
    Serial.print(" %\t");
    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println(" *C");

    if (motionState == HIGH)
    {
        // Motion detected
        Serial.println("Motion detected!");
    }
    else
    {
        // No motion detected
        Serial.println("No motion detected.");
    }

    delay(500); // Delay before next reading
}
