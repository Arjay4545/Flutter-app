# Arduino Integration for Soil Monitoring App

This guide explains how to connect your Arduino-based soil monitoring sensors to the Flutter app for real-time NPK (Nitrogen, Phosphorus, Potassium) data collection.

## 🔧 Hardware Requirements

### Arduino Board
- **Arduino Uno/Nano** (recommended for beginners)
- **ESP32** (for WiFi connectivity)
- **Arduino Mega** (for multiple sensors)

### Sensors
- **NPK Soil Sensor** (3-in-1 sensor recommended)
- **Individual N, P, K sensors** (alternative option)
- **pH Sensor** (optional)
- **Soil Moisture Sensor** (optional)
- **Temperature Sensor** (optional)

### Additional Components
- Jumper wires
- Breadboard or PCB
- USB cable for Arduino connection
- Power supply (if running standalone)

## 📋 Wiring Diagram

```
Arduino Uno    →    NPK Sensor
VCC (5V)       →    VCC (Red wire)
GND            →    GND (Black wire)
A0             →    Nitrogen Data (Yellow wire)
A1             →    Phosphorus Data (Green wire)
A2             →    Potassium Data (Blue wire)
Pin 13         →    Status LED (optional)
```

### For ESP32:
```
ESP32          →    NPK Sensor
3.3V           →    VCC
GND            →    GND
GPIO36 (A0)    →    Nitrogen Data
GPIO39 (A3)    →    Phosphorus Data
GPIO34 (A6)    →    Potassium Data
GPIO2          →    Status LED
```

## 🚀 Setup Instructions

### 1. Arduino IDE Setup

1. **Download Arduino IDE**: https://www.arduino.cc/en/software
2. **Install Required Libraries** (if using additional sensors):
   ```
   Tools → Manage Libraries → Search and install:
   - OneWire (for temperature sensors)
   - DallasTemperature (for DS18B20)
   - DHT sensor library (for humidity sensors)
   ```

### 2. Upload Arduino Sketch

1. **Open the sketch**: `arduino_examples/soil_monitoring_sensor.ino`
2. **Select your board**: `Tools → Board → Arduino Uno` (or your specific board)
3. **Select the port**: `Tools → Port → COM3` (Windows) or `/dev/ttyUSB0` (Linux)
4. **Upload the sketch**: Click the upload button (→)

### 3. Flutter App Setup

1. **Install dependencies**:
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run -d chrome  # For web
   flutter run -d windows # For desktop
   ```

3. **Connect to Arduino**:
   - Click the settings icon in the app
   - Select "Arduino Connection Settings"
   - Choose your Arduino's COM port
   - Click "Connect" or "Auto Connect"

## 📡 Communication Protocol

### Data Format
The Arduino sends sensor data in JSON format:
```json
{
  "nitrogen": 75.5,
  "phosphorus": 60.2,
  "potassium": 85.1
}
```

### Commands
Send these commands from Flutter to Arduino:

| Command | Description |
|---------|-------------|
| `READ_SENSORS` | Request immediate sensor reading |
| `CALIBRATE` | Start sensor calibration process |
| `AUTO_ON` | Enable automatic readings every 5 seconds |
| `AUTO_OFF` | Disable automatic readings |
| `PING` | Test connection (Arduino responds with "PONG") |
| `STATUS` | Get detailed sensor status |

### Serial Settings
- **Baud Rate**: 9600
- **Data Bits**: 8
- **Stop Bits**: 1
- **Parity**: None
- **Flow Control**: None

## 🔍 Troubleshooting

### Connection Issues

**Problem**: Arduino not detected
- **Solution**: Check USB cable and drivers
- **Windows**: Install CH340/CP2102 drivers if needed
- **Linux**: Add user to dialout group: `sudo usermod -a -G dialout $USER`

**Problem**: Permission denied (Linux/Mac)
- **Solution**: 
  ```bash
  sudo chmod 666 /dev/ttyUSB0  # Replace with your port
  # Or permanently:
  sudo usermod -a -G dialout $USER
  ```

**Problem**: Data not received in Flutter app
- **Solution**: 
  1. Check baud rate matches (9600)
  2. Verify wiring connections
  3. Test with Arduino Serial Monitor first
  4. Check if port is already in use

### Sensor Issues

**Problem**: Readings always 0 or 100
- **Solution**: 
  1. Check sensor power supply
  2. Verify analog pin connections
  3. Run calibration: Send `CALIBRATE` command
  4. Adjust `SENSOR_MIN` and `SENSOR_MAX` values in code

**Problem**: Erratic readings
- **Solution**:
  1. Add capacitors for power filtering
  2. Use shielded cables for sensors
  3. Increase reading interval
  4. Average multiple readings

## 🔧 Customization

### Adding More Sensors

To add pH sensor on pin A3:

```cpp
#define PH_PIN A3

void readPHSensor() {
  int phRaw = analogRead(PH_PIN);
  float phValue = mapFloat(phRaw, 0, 1023, 0.0, 14.0);
  
  // Add to JSON output
  Serial.print(", \"ph\": ");
  Serial.print(phValue, 1);
}
```

### Changing Data Format

For CSV format instead of JSON:
```cpp
void sendCSVData() {
  Serial.print(nitrogenLevel, 1);
  Serial.print(",");
  Serial.print(phosphorusLevel, 1);
  Serial.print(",");
  Serial.println(potassiumLevel, 1);
}
```

### WiFi Connectivity (ESP32)

For direct Firebase connection:
```cpp
#include <WiFi.h>
#include <FirebaseESP32.h>

const char* ssid = "your_wifi_ssid";
const char* password = "your_wifi_password";

void setup() {
  WiFi.begin(ssid, password);
  // Firebase setup code
}
```

## 📊 Sensor Calibration

### Manual Calibration Steps

1. **Prepare reference solutions** with known NPK concentrations
2. **Send `CALIBRATE` command** from Flutter app
3. **Immerse sensors** in reference solutions
4. **Record baseline values** displayed in Serial Monitor
5. **Update calibration constants** in Arduino code:
   ```cpp
   #define NITROGEN_MIN 100    // Update with your values
   #define NITROGEN_MAX 900
   ```

### Automatic Calibration

The Arduino can perform automatic calibration:
- Takes 50 samples over 5 seconds
- Calculates average baseline values
- Stores in EEPROM for persistence

## 🔋 Power Management

### Battery Operation
```cpp
#include <LowPower.h>

void loop() {
  readSensors();
  sendData();
  
  // Sleep for 8 seconds to save battery
  LowPower.powerDown(SLEEP_8S, ADC_OFF, BOD_OFF);
}
```

### Solar Charging
- Use TP4056 charging module
- Add voltage divider for battery monitoring
- Implement low-battery protection

## 📱 Mobile App Integration

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to Arduino sensors</string>
```

## 🌐 Advanced Features

### Web Dashboard
- Real-time sensor monitoring
- Historical data visualization
- Remote sensor configuration
- Alert notifications

### Data Logging
- SD card storage for offline operation
- Automatic data sync when connected
- Backup and recovery features

### Multiple Sensor Support
- Support for multiple Arduino devices
- Sensor network management
- Distributed monitoring system

## 📞 Support

### Common Serial Commands for Testing

Open Arduino Serial Monitor (Tools → Serial Monitor) and try:
```
READ_SENSORS    → Should return JSON data
PING           → Should return "PONG - Arduino is connected"
STATUS         → Shows detailed sensor information
CALIBRATE      → Starts calibration process
```

### Debug Mode

Enable debug output in Arduino code:
```cpp
#define DEBUG_MODE true

void debugPrint(String message) {
  if (DEBUG_MODE) {
    Serial.println("[DEBUG] " + message);
  }
}
```

### Getting Help

1. **Check Serial Monitor** for Arduino debug messages
2. **Verify wiring** with multimeter
3. **Test sensors individually** before integration
4. **Check Flutter console** for connection errors
5. **Update drivers** if connection fails

## 📈 Performance Tips

- Use hardware serial for faster communication
- Implement data buffering for reliable transmission
- Add checksums for data integrity
- Use interrupts for real-time responsiveness
- Optimize power consumption for battery operation

---

**Happy Monitoring!** 🌱

For more help, check the Arduino community forums or create an issue in this repository.
