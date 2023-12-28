#include "UWBDevice.h"

UWBDevice::UWBDevice(const String &identifier) : id(identifier)
{
    this->sleepTime = -1;
    this->lastCommunication = -1;
}

String UWBDevice::getId() const 
{ 
    return id; 
}

unsigned long UWBDevice::getSleepTime() const 
{ 
    return sleepTime; 
}

void UWBDevice::setSleepTime(unsigned long time) 
{ 
    sleepTime = time; 
}

void UWBDevice::updateLastCommunication(unsigned long time) 
{ 
    lastCommunication = time; 
}

bool UWBDevice::isTimeToCommunicate(unsigned long currentTime) 
{ 
    return (currentTime - lastCommunication) >= sleepTime; 
}