#pragma once

#include "Arduino.h"

#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace Utils 
{
    class StringUtils
    {
        public:
            static std::vector<String> parseString(const char* str, const char& divider)
            {
                std::vector<String> result;

                std::stringstream ss(str);
                std::string token;
                int i = 0;

                while (std::getline(ss, token, divider))
                {
                    result.push_back(token.c_str());
                    ++i;
                }

                return result;
            }

            static std::vector<String> parseUnderscoreString(const String& str, const char& divider)
            {
                return parseString(str.c_str(), divider);
            }
            
            static std::vector<String> parseUnderscoreString(const std::string& str, const char& divider)
            {
                return parseString(str.c_str(), divider);
            }
    };
}