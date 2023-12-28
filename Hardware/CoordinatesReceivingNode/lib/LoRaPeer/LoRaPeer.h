#pragma once

#include "LoRaWan_APP.h"
#include "Arduino.h"

#include <map>
#include <set>
#include <queue>

#define BUFFER_SIZE 2047 // Define the payload size

namespace LoRaDevice
{
    // TODO: In future swap all of that so I communicate only with a gateway and not like a pure peer
    // TODO: When a peer join the network it sends his public key to the gateway, then the gateway handle everything

    // TODO: Implement Diffie-Hellman protocol in order to exchange private keys for decrypt and encrypt
    class LoRaPeer
    {
        private:
            struct Message 
            {
                String body;
                String header;
                String destination;
                String uuid;
                int orderNumber;
                long lastTimestamp;
                int retries;
            };

            struct ReceivedMessage
            {
                String body;
                String sender;
            };

            enum MessageType
            {
                BROADCAST,
                DIRECT
            };

            // Internal state and configuration
            enum States_t
            {
                LOWPOWER,
                STATE_RX,
                STATE_TX
            };

            static LoRaPeer* instance;
            const char messageDivider = '_';

            int messageCounter = 0;

            std::map<String, Message> messagesStatus;
            std::queue<Message> messageQueue;

            static char txpacket[BUFFER_SIZE];
            static char rxpacket[BUFFER_SIZE];
            static RadioEvents_t RadioEvents;
            static int16_t Rssi, rxSize;
            static States_t state;

            static int sentPacketNumber;
            static int receivedPacketNumber;
            
            String generateMessageUUID();

            void checkSentMessages();

            // Call this function to send a message
            void send(const char* msg);
            void send(const String& msg);

            void sendACK(const char* senderID);
            void sendACK(const String& senderID);

            // Callbacks for LoRa events
            static void OnTxDone(void);
            static void OnTxTimeout(void);
            static void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr);

        public:
            std::map<String, ReceivedMessage> receivedMessages;

            LoRaPeer();

            void broadcastMessage(const char *msg);
            void broadcastMessage(const String& msg);

            void sendMessage(const char *msg, const char* destination);
            void sendMessage(const String& msg, const String& destination);

            void sendHeartbeat();

            // Call this function regularly to process incoming messages and other tasks
            void loop();
    };
}
