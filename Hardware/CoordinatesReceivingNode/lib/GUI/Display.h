#pragma once

#include "Arduino.h"
#include "HT_SSD1306Wire.h"

namespace GUI {
    class Display {
        private:
            int currentLine;
            int lineIncrementFactor;

            SSD1306Wire display;

            static Display* instance;

            Display();

        public:
            static Display& getInstance();

            void write(const String& txtToWrite);
            void append(const String& txtToAppend);

            void operator += (const String& txtToAppend);
            void operator += (const char* txtToAppend);

            void clear();
    };
}