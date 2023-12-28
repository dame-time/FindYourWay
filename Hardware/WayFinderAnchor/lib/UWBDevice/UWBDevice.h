#pragma once

#include <Arduino.h>

class UWBDevice
{
    public:
        UWBDevice(const String &identifier);

        String getId() const;
        unsigned long getSleepTime() const;
        void setSleepTime(unsigned long time);
        void updateLastCommunication(unsigned long time);
        bool isTimeToCommunicate(unsigned long currentTime);

    private:
        String id;
        unsigned long sleepTime;        
        unsigned long lastCommunication;
};
