/*
  ESP32 Soil Monitoring with Direct Firebase Integration
  
  This sketch reads NPK sensor data and sends it directly to Firebase Realtime Database
  without requiring the Flutter app to be running. The Flutter app can still read
  the data from Firebase for display and analytics.
  
  Hardware Requirements:
  - ESP32 Development Board
  - NPK Soil Sensor (or individual N, P, K sensors)
  - Optional: pH sensor, moisture sensor, temperature sensor
  
  Libraries Required (install via Arduino Library Manager):
  - Firebase ESP32 Client by Mobizt
  - WiFi (built-in)
  - ArduinoJson (for data formatting)
  
  Firebase Project: soil-monitoring-a2675
  Database URL: https://soil-monitoring-a2675-default-rtdb.firebaseio.com
*/

#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ArduinoJson.h>
#include <time.h>

// WiFi credentials
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase configuration
#define FIREBASE_HOST "soil-monitoring-a2675-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_DATABASE_SECRET"  // Get from Firebase Console > Project Settings > Service Accounts > Database Secrets

// Pin definitions for ESP32
#define NITROGEN_PIN 36    // GPIO36 (A0)
#define PHOSPHORUS_PIN 39  // GPIO39 (A3)
#define POTASSIUM_PIN 34   // GPIO34 (A6)
#define LED_PIN 2          // Built-in LED
#define MOISTURE_PIN 35    // Optional moisture sensor
#define PH_PIN 32          // Optional pH sensor

// Sensor calibration values
#define NITROGEN_MIN 0
#define NITROGEN_MAX 4095  // ESP32 ADC is 12-bit (0-4095)
#define PHOSPHORUS_MIN 0
#define PHOSPHORUS_MAX 4095
#define POTASSIUM_MIN 0
#define POTASSIUM_MAX 4095

// Timing variables
unsigned long lastReading = 0;
const unsigned long READING_INTERVAL = 30000; // Read every 30 seconds
const unsigned long WIFI_TIMEOUT = 10000;     // WiFi connection timeout

// Firebase objects
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// Sensor values
float nitrogenLevel = 0.0;
float phosphorusLevel = 0.0;
float potassiumLevel = 0.0;
float moistureLevel = 0.0;
float phLevel = 0.0;
float temperature = 0.0;

// Device info
String deviceId = "ESP32_001";
bool wifiConnected = false;
bool firebaseConnected = false;

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 Soil Monitoring System Starting...");
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(NITROGEN_PIN, INPUT);
  pinMode(PHOSPHORUS_PIN, INPUT);
  pinMode(POTASSIUM_PIN, INPUT);
  pinMode(MOISTURE_PIN, INPUT);
  pinMode(PH_PIN, INPUT);
  
  // Generate unique device ID based on MAC address
  deviceId = "ESP32_" + WiFi.macAddress();
  deviceId.replace(":", "");
  
  // Initialize WiFi
  initWiFi();
  
  // Initialize Firebase
  initFirebase();
  
  // Initialize time (for timestamps)
  configTime(8 * 3600, 0, "pool.ntp.org"); // UTC+8 timezone
  
  Serial.println("Setup complete!");
  blinkLED(3, 200); // 3 quick blinks to indicate ready
}

void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    Serial.println("WiFi disconnected. Reconnecting...");
    initWiFi();
  } else {
    wifiConnected = true;
  }
  
  // Read sensors and send to Firebase
  if (millis() - lastReading >= READING_INTERVAL) {
    if (wifiConnected) {
      readSensors();
      sendToFirebase();
      lastReading = millis();
    }
  }
  
  // Handle serial commands for debugging
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    handleSerialCommand(command);
  }
  
  delay(1000);
}

void initWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  unsigned long startTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startTime < WIFI_TIMEOUT) {
    delay(500);
    Serial.print(".");
    digitalWrite(LED_PIN, !digitalRead(LED_PIN)); // Blink while connecting
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    digitalWrite(LED_PIN, HIGH);
    Serial.println();
    Serial.println("WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Device ID: ");
    Serial.println(deviceId);
  } else {
    wifiConnected = false;
    digitalWrite(LED_PIN, LOW);
    Serial.println();
    Serial.println("WiFi connection failed!");
  }
}

void initFirebase() {
  if (!wifiConnected) return;
  
  Serial.println("Initializing Firebase...");
  
  // Configure Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Test Firebase connection
  if (Firebase.ready()) {
    firebaseConnected = true;
    Serial.println("Firebase connected successfully!");
    
    // Register device
    registerDevice();
  } else {
    firebaseConnected = false;
    Serial.println("Firebase connection failed!");
  }
}

void readSensors() {
  Serial.println("Reading sensors...");
  digitalWrite(LED_PIN, HIGH);
  
  // Read raw sensor values
  int nitrogenRaw = analogRead(NITROGEN_PIN);
  int phosphorusRaw = analogRead(PHOSPHORUS_PIN);
  int potassiumRaw = analogRead(POTASSIUM_PIN);
  int moistureRaw = analogRead(MOISTURE_PIN);
  int phRaw = analogRead(PH_PIN);
  
  // Convert to percentage/meaningful values
  nitrogenLevel = mapFloat(nitrogenRaw, NITROGEN_MIN, NITROGEN_MAX, 0.0, 100.0);
  phosphorusLevel = mapFloat(phosphorusRaw, PHOSPHORUS_MIN, PHOSPHORUS_MAX, 0.0, 100.0);
  potassiumLevel = mapFloat(potassiumRaw, POTASSIUM_MIN, POTASSIUM_MAX, 0.0, 100.0);
  moistureLevel = mapFloat(moistureRaw, 0, 4095, 0.0, 100.0);
  phLevel = mapFloat(phRaw, 0, 4095, 0.0, 14.0);
  
  // Get temperature from internal sensor (rough estimate)
  temperature = (temprature_sens_read() - 32) / 1.8; // Convert to Celsius
  
  // Constrain values
  nitrogenLevel = constrain(nitrogenLevel, 0.0, 100.0);
  phosphorusLevel = constrain(phosphorusLevel, 0.0, 100.0);
  potassiumLevel = constrain(potassiumLevel, 0.0, 100.0);
  moistureLevel = constrain(moistureLevel, 0.0, 100.0);
  phLevel = constrain(phLevel, 0.0, 14.0);
  
  // Print readings
  Serial.println("=== Sensor Readings ===");
  Serial.println("Nitrogen: " + String(nitrogenLevel, 1) + "%");
  Serial.println("Phosphorus: " + String(phosphorusLevel, 1) + "%");
  Serial.println("Potassium: " + String(potassiumLevel, 1) + "%");
  Serial.println("Moisture: " + String(moistureLevel, 1) + "%");
  Serial.println("pH: " + String(phLevel, 1));
  Serial.println("Temperature: " + String(temperature, 1) + "°C");
  Serial.println("=======================");
  
  digitalWrite(LED_PIN, LOW);
}

void sendToFirebase() {
  if (!firebaseConnected || !Firebase.ready()) {
    Serial.println("Firebase not ready");
    return;
  }
  
  Serial.println("Sending data to Firebase...");
  
  // Get current timestamp
  time_t now;
  time(&now);
  
  // Create JSON object for current data
  DynamicJsonDocument currentDoc(1024);
  currentDoc["nitrogen"] = nitrogenLevel;
  currentDoc["phosphorus"] = phosphorusLevel;
  currentDoc["potassium"] = potassiumLevel;
  currentDoc["moisture"] = moistureLevel;
  currentDoc["ph"] = phLevel;
  currentDoc["temperature"] = temperature;
  currentDoc["timestamp"] = now;
  currentDoc["deviceId"] = deviceId;
  currentDoc["lastUpdate"] = now;
  
  String currentJson;
  serializeJson(currentDoc, currentJson);
  
  // Send current data
  if (Firebase.setString(firebaseData, "/soil_monitoring/current", currentJson)) {
    Serial.println("Current data sent successfully");
  } else {
    Serial.println("Failed to send current data: " + firebaseData.errorReason());
  }
  
  // Create JSON object for historical data
  DynamicJsonDocument historyDoc(1024);
  historyDoc["nitrogen"] = nitrogenLevel;
  historyDoc["phosphorus"] = phosphorusLevel;
  historyDoc["potassium"] = potassiumLevel;
  historyDoc["moisture"] = moistureLevel;
  historyDoc["ph"] = phLevel;
  historyDoc["temperature"] = temperature;
  historyDoc["deviceId"] = deviceId;
  
  String historyJson;
  serializeJson(historyDoc, historyJson);
  
  // Send historical data with timestamp as key
  String historyPath = "/soil_monitoring/history/" + String(now);
  if (Firebase.setString(firebaseData, historyPath, historyJson)) {
    Serial.println("Historical data sent successfully");
  } else {
    Serial.println("Failed to send historical data: " + firebaseData.errorReason());
  }
  
  // Update device status
  updateDeviceStatus();
  
  // Blink LED to indicate successful transmission
  blinkLED(2, 100);
}

void registerDevice() {
  Serial.println("Registering device...");
  
  DynamicJsonDocument deviceDoc(512);
  deviceDoc["deviceId"] = deviceId;
  deviceDoc["type"] = "ESP32_SoilMonitor";
  deviceDoc["location"] = "Field_001";
  deviceDoc["lastSeen"] = time(nullptr);
  deviceDoc["status"] = "online";
  deviceDoc["firmware"] = "1.0.0";
  deviceDoc["sensors"] = "NPK,pH,Moisture,Temperature";
  
  String deviceJson;
  serializeJson(deviceDoc, deviceJson);
  
  String devicePath = "/devices/" + deviceId;
  if (Firebase.setString(firebaseData, devicePath, deviceJson)) {
    Serial.println("Device registered successfully");
  } else {
    Serial.println("Failed to register device: " + firebaseData.errorReason());
  }
}

void updateDeviceStatus() {
  time_t now;
  time(&now);
  
  String statusPath = "/devices/" + deviceId + "/lastSeen";
  Firebase.setInt(firebaseData, statusPath, now);
  
  String onlinePath = "/devices/" + deviceId + "/status";
  Firebase.setString(firebaseData, onlinePath, "online");
}

void handleSerialCommand(String command) {
  command.toUpperCase();
  
  if (command == "READ") {
    readSensors();
  }
  else if (command == "SEND") {
    sendToFirebase();
  }
  else if (command == "STATUS") {
    printStatus();
  }
  else if (command == "RESTART") {
    ESP.restart();
  }
  else if (command == "WIFI") {
    initWiFi();
  }
  else if (command == "FIREBASE") {
    initFirebase();
  }
  else {
    Serial.println("Available commands: READ, SEND, STATUS, RESTART, WIFI, FIREBASE");
  }
}

void printStatus() {
  Serial.println("=== ESP32 Status ===");
  Serial.println("Device ID: " + deviceId);
  Serial.println("WiFi: " + String(wifiConnected ? "Connected" : "Disconnected"));
  if (wifiConnected) {
    Serial.println("IP: " + WiFi.localIP().toString());
    Serial.println("RSSI: " + String(WiFi.RSSI()) + " dBm");
  }
  Serial.println("Firebase: " + String(firebaseConnected ? "Connected" : "Disconnected"));
  Serial.println("Uptime: " + String(millis() / 1000) + " seconds");
  Serial.println("Free Heap: " + String(ESP.getFreeHeap()) + " bytes");
  Serial.println("Last Reading: " + String((millis() - lastReading) / 1000) + " seconds ago");
  Serial.println("===================");
}

void blinkLED(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(delayMs);
    digitalWrite(LED_PIN, LOW);
    delay(delayMs);
  }
}

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

/*
  Configuration Notes:
  
  1. Update WiFi credentials:
     - WIFI_SSID: Your WiFi network name
     - WIFI_PASSWORD: Your WiFi password
  
  2. Get Firebase Database Secret:
     - Go to Firebase Console
     - Project Settings > Service Accounts
     - Database Secrets tab
     - Copy the secret key
  
  3. Sensor Wiring for ESP32:
     - VCC -> 3.3V (ESP32 uses 3.3V logic)
     - GND -> GND
     - Nitrogen -> GPIO36 (A0)
     - Phosphorus -> GPIO39 (A3)
     - Potassium -> GPIO34 (A6)
     - Moisture -> GPIO35 (A7)
     - pH -> GPIO32 (A4)
  
  4. Firebase Database Structure:
     /soil_monitoring/current - Latest readings
     /soil_monitoring/history/{timestamp} - Historical data
     /devices/{deviceId} - Device information
  
  5. Power Considerations:
     - ESP32 can run on battery with deep sleep
     - Add solar panel for continuous operation
     - Monitor battery voltage on GPIO33
  
  6. Advanced Features:
     - OTA updates for remote firmware updates
     - Web server for local configuration
     - MQTT for real-time communication
     - Multiple sensor support
*/
