#include <Device.h>

Device *Device::instance = nullptr;

Device::Device()
{
    this->uuid = loraUUIDs[0];
}

Device *Device::getInstance()
{
    if (instance == nullptr)
        instance = new Device();

    return instance;
}

void Device::setUUID(UUIDType uuidType)
{
    this->uuid = loraUUIDs[uuidType];
}

String Device::getUUID()
{
    return this->uuid;
}

BLEUUIDs Device::getBLEPairedUUID()
{
    if (this->uuid == loraUUIDs[0])
        return bleUuids[0];
    else if (this->uuid == loraUUIDs[1])
        return bleUuids[1];
    else if (this->uuid == loraUUIDs[2])
        return bleUuids[2];
    else
        return bleUuids[0];
}