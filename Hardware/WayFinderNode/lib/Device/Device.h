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
};

class Device
{
    private: 
        static Device* instance;

        const char* uwbUuids[3] = {
            "UWB_DAME_001",
            "UWB_DAME_002",
            "UWB_DAME_003"
        };

        BLEUUIDs bleUuids[3] = {
            BLEUUIDs{"4fafc201-1fb5-459e-8fcc-c5c9c331914b", "beb5483e-36e1-4688-b7f5-ea07361b26a8"},
            BLEUUIDs{"981809ac-bc61-4e48-a005-e08d7494dd87", "24db9359-e90b-4f41-8a14-f8830e52a6af"},
            BLEUUIDs{"a435660e-af60-4003-8e2a-85fa158dfeb5", "4e66d9ad-589f-4b47-9690-ec3f985f3b28"}};

        String uuid;

        Device();

    public:
        static Device* getInstance();

        void setUUID(UUIDType uuidType);

        String getUUID();
        BLEUUIDs getBLEPairedUUID();
};