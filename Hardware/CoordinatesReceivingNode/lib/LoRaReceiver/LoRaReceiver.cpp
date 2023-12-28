#include "LoRaReceiver.hpp"

#include <Display.h>

#define RF_FREQUENCY 868000000 // Hz

#define TX_OUTPUT_POWER 20 // dBm

#define LORA_BANDWIDTH 2        // [0: 125 kHz,
                                //  1: 250 kHz,
                                //  2: 500 kHz,
                                //  3: Reserved]
#define LORA_SPREADING_FACTOR 6 // [SF7..SF12]
#define LORA_CODINGRATE 1       // [1: 4/5,
                                //  2: 4/6,
                                //  3: 4/7,
                                //  4: 4/8]
#define LORA_PREAMBLE_LENGTH 4  // Same for Tx and Rx
#define LORA_SYMBOL_TIMEOUT 0   // Symbols
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false

#define RX_TIMEOUT_VALUE 1000

LoRaReceiver* LoRaReceiver::instance = nullptr;

LoRaReceiver::LoRaReceiver()
{
    RadioEvents.RxTimeout = OnRxTimeout;
    RadioEvents.RxDone = OnRxDone;

    // Initialize the LoRa radio
    Radio.Init(&RadioEvents);
    Radio.SetChannel(RF_FREQUENCY);
    Radio.SetRxConfig(MODEM_LORA, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                      LORA_CODINGRATE, 0, LORA_PREAMBLE_LENGTH,
                      LORA_SYMBOL_TIMEOUT, LORA_FIX_LENGTH_PAYLOAD_ON,
                      0, true, 0, 0, LORA_IQ_INVERSION_ON, true);

    rxDone = true;
}

LoRaReceiver* LoRaReceiver::getInstance()
{
    if (instance == nullptr)
        instance = new LoRaReceiver();

    return instance;
}

void LoRaReceiver::receive()
{
    if (rxDone)
    {
        rxDone = false;
        Radio.Rx(0);
    }

    Radio.IrqProcess();
}

// TODO: Setup an ACK message
void LoRaReceiver::OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr)
{
    String payloadString = String((const char *)payload);

    GUI::Display::getInstance().clear();
    GUI::Display::getInstance() += "Received message: \n" + payloadString + "\n";

    Serial.println("Received message: " + payloadString + ", Length: " + String(size) + ", RSSI: " + String(rssi) + ", SNR: " + String(snr));

    instance->rxDone = true;
}

void LoRaReceiver::OnRxTimeout(void)
{
    Serial.println("RX Timeout");

    instance->rxDone = true;
}
