#include <UWBScheduler.h>

UWBScheduler* uwbScheduler;

void setup()
{
    UWBDevice uwbDevice0 = UWBDevice("UWB_DAME_001");
    UWBDevice uwbDevice1 = UWBDevice("UWB_DAME_002");
    UWBDevice uwbDevice2 = UWBDevice("UWB_DAME_003");

    uwbScheduler = new UWBScheduler();

    uwbScheduler->addDevice(uwbDevice0);
    uwbScheduler->addDevice(uwbDevice1);
    uwbScheduler->addDevice(uwbDevice2);

    uwbScheduler->scheduleCommunication();
}

void loop()
{
    uwbScheduler->startCommunication();
    uwbScheduler->processIncomingMessage();
}