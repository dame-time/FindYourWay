# FindYourWay

## Overview

"Find Your Way" is an advanced, user-friendly Internal Positioning System (IPS) with wayfinding capabilities, designed to meet the needs of both public and corporate environments. The application offers a dual setup: one tailored for personal use and another encompassing an admin platform for user management and geofence breach notifications.

## Features

- **Indoor Navigation**: Leverage precise UWB technology for pinpoint accuracy in indoor navigation.
- **Geofencing**: Monitor and manage geofenced areas with real-time alerts for any breaches.
- **Multi-Platform**: Accessible via a mobile app and an admin web interface, both created using Flutter for a unified user experience.
- **Secure Authentication**: Utilizes AWS KMS for robust key management and secure encryption of user credentials.
- **Logging**: Extensive logging of user actions on the admin platform, stored and accessible on a Raspberry Pi station.

## Hardware Components

The system's reliability and precision come from a well-integrated hardware setup, which includes:

- **Raspberry Pi 4B**: Acts as a webserver and logger.
- **STM32 Nucleo & Arduino Uno**: Serve as environmental markers.
- **Heltec Automation ESP32 LoRa WiFi V3**: Four units, three for MQTT user coordinate communication and one for geofencing marker communication.
- **ESP32 with UWB Sensors**: Three nodes for position triangulation and one anchor point for reference.
- **AM312 Motion Sensors**: For movement tracking in geofenced zones.
- **DHT11 Sensors**: For monitoring temperature and humidity in geofenced areas.

## Software Architecture

At the heart of "Find Your Way" is a mobile application and an administrative web interface, both developed using the Flutter framework. This ensures a consistent user experience across different platforms and devices. The application is designed to interact seamlessly with a suite of cloud services and distributed hardware components as outlined:

- **Client-Side**: A mobile app for end-users and a web admin interface for system administration.
- **Server and Middleware**: A Flask-based RaspberryPi webserver connects the admin interface with cloud services, handled by AWS Lambda functions in Python.
- **Hardware and Connectivity**: STM32 Nucleo for geofencing, ESP32 nodes for UWB-based positioning, and sensors for environmental monitoring and motion detection.

## Getting Started

To set up "Find Your Way", follow the instructions in the respective folders:

1. **/MobileApp**: Contains the Flutter project for the mobile application.
2. **/AdminPlatform**: Houses the Flutter project for the admin web interface.
3. **/Hardware**: Includes schematics and code for setting up the hardware components.
4. **/Server**: Contains the Flask server code and deployment instructions.

## Documentation

For a detailed explanation of the system's architecture and how to use each component, please refer to the documentation in the `/docs` directory.

## Contributions

We welcome contributions to "Find Your Way". Please read `CONTRIBUTING.md` for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the `LICENSE.md` file for details.

## Acknowledgments

- Thanks to Professor Bruschi for providing the STM32 Nucleo boards.
- Shoutout to the team at Heltec Automation for their excellent ESP32 LoRa modules.
- Appreciation to all contributors and testers who have helped to shape "Find Your Way".

We hope "Find Your Way" empowers you to navigate and manage indoor spaces with ease and precision!
