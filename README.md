# SmartControlMonitorSystem

---

# Project Title

SmartControlMonitorSystem

## Overview

This repository contains a project integrating a Flutter app for Android, Arduino code in C++, and a JavaScript file for serial communication.
## Table of Contents

- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [Flutter Installation](#flutter-installation)
    - [Installing Dependencies](#installing-dependencies)
- [Usage](#usage)
  - [Running the Flutter App](#running-the-flutter-app)
  - [Uploading the Arduino Code](#uploading-the-arduino-code)
  - [Running the Serial Proxy](#running-the-serial-proxy)
- [Acknowledgements](#acknowledgements)

## Getting Started

### Prerequisites

Ensure you have the following software installed:

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Arduino IDE](https://www.arduino.cc/en/software)
- [Node.js](https://nodejs.org/)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/your-repo-name.git
   cd your-repo-name
   ```

#### Flutter Installation

2. **Install Flutter:**

   Follow the [official installation guide for Windows](https://flutter.dev/docs/get-started/install/windows).

   - Download the Flutter SDK from the [Flutter website](https://flutter.dev/docs/get-started/install/windows#install-flutter-manually).
   - Extract the zip file and place the contained `flutter` folder in the desired installation location (e.g., `C:\src\flutter`).

3. **Update your PATH:**

   - From the Start search bar, enter ‘env’ and select ‘Edit environment variables for your account’.
   - Under ‘User variables’, check if there is an entry called `Path`:
     - If the entry exists, append the full path to `flutter\bin` using `;` as a separator from existing values.
     - If the entry does not exist, create a new user variable named `Path` with the full path to `flutter\bin` as its value.

4. **Verify Flutter installation:**

   Open a new Command Prompt window and run:

   ```bash
   flutter doctor
   ```

   Follow the instructions provided by `flutter doctor` to complete the setup. This may include installing additional dependencies like the Android SDK.

#### Installing Dependencies

5. **Navigate to the Flutter app directory:**

   ```bash
   cd path/to/flutter-app
   ```

6. **Install Flutter dependencies:**

   ```bash
   flutter pub get
   ```

7. **Install dependencies for the serial proxy:**

   ```bash
   cd path/to/serial-proxy
   npm install
   ```

## Usage

### Running the Flutter App

1. Navigate to the Flutter app directory:

   ```bash
   cd path/to/flutter-app
   ```

2. Run the Flutter app on an Android device or emulator:

   ```bash
   flutter run
   ```

### Uploading the Arduino Code

1. Open the Arduino IDE.
2. Open the `path/to/arduino-code.ino` file.
3. Connect your Arduino device.
4. Select the correct board and port from the Tools menu.
5. Upload the code to the Arduino.

### Running the Serial Proxy

1. Navigate to the serial proxy directory:

   ```bash
   cd path/to/serial-proxy
   ```

2. Run the proxy server:

   ```bash
   node Serial-Proxy.js
   ```


## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Arduino](https://www.arduino.cc/)
- [Node.js](https://nodejs.org/)

---
