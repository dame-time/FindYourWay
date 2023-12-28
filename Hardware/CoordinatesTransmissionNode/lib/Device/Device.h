#pragma once

#include <Arduino.h>

enum UUIDType
{
    DEVICE_001,
    DEVICE_002,
    DEVICE_003
};

struct BLEUUIDs
{
    const char *serviceUUID;
    const char *characteristicUUID;
    const char *serverAddress;
    const char *descriptorUUID;
};

class Device
{
private:
    static Device *instance;

    const char *loraUUIDs[3] = {
        "LoRa_DAME_001",
        "LoRa_DAME_002",
        "LoRa_DAME_003"};

    BLEUUIDs bleUuids[3] = {
        BLEUUIDs{"4fafc201-1fb5-459e-8fcc-c5c9c331914b", "beb5483e-36e1-4688-b7f5-ea07361b26a8", "40:22:d8:07:30:d6", "00002902-0000-1000-8000-00805f9b34fb"},
        BLEUUIDs{"981809ac-bc61-4e48-a005-e08d7494dd87", "24db9359-e90b-4f41-8a14-f8830e52a6af", "40:22:d8:06:05:ea", "00002902-0000-1000-8000-00805f9b34fb"},
        BLEUUIDs{"a435660e-af60-4003-8e2a-85fa158dfeb5", "4e66d9ad-589f-4b47-9690-ec3f985f3b28", "94:b5:55:2b:6d:3e", "00002902-0000-1000-8000-00805f9b34fb"}};

    String uuid;

    Device();

public:
    static Device *getInstance();

    void setUUID(UUIDType uuidType);

    String getUUID();
    BLEUUIDs getBLEPairedUUID();
};