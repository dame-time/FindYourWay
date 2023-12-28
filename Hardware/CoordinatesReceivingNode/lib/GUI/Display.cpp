#include <Display.h>

namespace GUI {
    Display* Display::instance = nullptr;

    Display::Display() : display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED) {
        currentLine = 0;
        lineIncrementFactor = 10;

        display.init();
        display.flipScreenVertically();
        display.setFont(ArialMT_Plain_10);
        display.setTextAlignment(TEXT_ALIGN_LEFT);
    }

    Display& Display::getInstance() {
        if (instance == nullptr)
            instance = new Display();

        return *instance;
    }

    void Display::write(const String &txtToWrite) {
        clear();
        display.drawString(0, lineIncrementFactor * currentLine, txtToWrite);
        display.display();
        ++currentLine;
    }

    void Display::append(const String &txtToAppend) {
        display.drawString(0, lineIncrementFactor * currentLine, txtToAppend);
        display.display();
        ++currentLine;
    }

    void Display::operator += (const String &txtToAppend) {
        append(txtToAppend);
    }
    
    void Display::operator += (const char* txtToAppend) {
        append(String(txtToAppend));
    }

    void Display::clear() {
        display.clear();
        currentLine = 0;
    }
}