# Flutter MQTT Communication App

## Overview

This Flutter application integrates with MongoDB Compass for user authentication and utilizes MQTT for real-time data communication. The app displays weight data received from an MQTT server in a scale widget and provides alerts for gas leakage using in-app notifications and the Awesome Notifications package.

## Features

- **User Authentication**: Sign up and log in using MongoDB Compass for managing user data.
- **MQTT Communication**: Subscribe to MQTT topics and receive real-time weight data.
- **Weight Display**: Visualize the received weight data in a scale widget.
- **Gas Leakage Alerts**: Receive notifications and in-app alerts for gas leakage events.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart
- MongoDB Compass (for user authentication)
- MQTT Broker (for data communication)
- Awesome Notifications package

### Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/your-flutter-mqtt-app.git
   cd your-flutter-mqtt-app
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure MongoDB Compass**

   Set up your MongoDB Compass database and configure it to handle user authentication.

4. **Configure MQTT**

   Update the MQTT connection settings in your Flutter project to connect to your MQTT broker.

5. **Set Up Notifications**

   Follow the [Awesome Notifications package documentation](https://pub.dev/packages/awesome_notifications) to configure notifications in your Flutter app.

### Usage

1. **Run the App**

   ```bash
   flutter run
   ```

2. **Login/Signup**

   Use the authentication module to create a new account or log in.

3. **MQTT Communication**

   Connect to the MQTT broker, subscribe to relevant topics, and start receiving weight data.

4. **View Weight Data**

   The weight data will be displayed in a scale widget on the main screen.

5. **Receive Alerts**

   Gas leakage alerts will be shown both as in-app notifications and system notifications.
