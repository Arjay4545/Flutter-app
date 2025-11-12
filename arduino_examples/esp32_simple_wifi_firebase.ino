/*
  ESP32 Soil Monitoring with WiFi Hotspot and Firebase
  Simple Arduino IDE code for ESP32 module
  
  Required Libraries (Install via Arduino Library Manager):
  1. Firebase ESP32 Client by Mobizt
  2. ArduinoJson by Benoit Blanchon
  
  Board: ESP32 Dev Module
  Upload Speed: 921600
  CPU Frequency: 240MHz (WiFi/BT)
  Flash Frequency: 80MHz
  Flash Mode: QIO
  Flash Size: 4MB (32Mb)
  Partition Scheme: Default 4MB with spiffs (1.2MB APP/1.5MB SPIFFS)
  Core Debug Level: None
  PSRAM: Disabled
*/

#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ArduinoJson.h>

// ========== CONFIGURATION - CHANGE THESE VALUES ==========
const char* WIFI_SSID = "YourHotspotName";        // Change to your WiFi hotspot name
const char* WIFI_PASSWORD = "YourHotspotPassword"; // Change to your WiFi password

// Firebase configuration
#define FIREBASE_HOST "soil-monitoring-a2675-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "AIzaSyChAulGpiXsPmIACunp6zSxzfWKT6NXYZA"  // Your Firebase Web API Key

// ========== PIN CONFIGURATION ==========
#define NITROGEN_PIN 36    // GPIO36 (A0) - Nitrogen sensor
#define PHOSPHORUS_PIN 39  // GPIO39 (A3) - Phosphorus sensor  
#define POTASSIUM_PIN 34   // GPIO34 (A6) - Potassium sensor
#define LED_PIN 2          // Built-in LED for status

// ========== GLOBAL VARIABLES ==========
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

String deviceId;
bool wifiConnected = false;
bool firebaseReady = false;

unsigned long lastSensorReading = 0;
const unsigned long SENSOR_INTERVAL = 30000; // Read sensors every 30 seconds

float nitrogen = 0.0;
float phosphorus = 0.0;
float potassium = 0.0;

// ========== SETUP FUNCTION ==========
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== ESP32 Soil Monitor Starting ===");
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(NITROGEN_PIN, INPUT);
  pinMode(PHOSPHORUS_PIN, INPUT);
  pinMode(POTASSIUM_PIN, INPUT);
  
  // Create unique device ID from MAC address
  deviceId = "ESP32_" + WiFi.macAddress();
  deviceId.replace(":", "");
  Serial.println("Device ID: " + deviceId);
  
  // Connect to WiFi
  connectToWiFi();
  
  // Initialize Firebase
  if (wifiConnected) {
    initializeFirebase();
  }
  
  Serial.println("=== Setup Complete ===\n");
  blinkLED(3, 200); // 3 blinks = ready
}

// ========== MAIN LOOP ==========
void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    Serial.println("WiFi disconnected! Reconnecting...");
    connectToWiFi();
  }
  
  // Read sensors and send to Firebase every 30 seconds
  if (wifiConnected && firebaseReady && (millis() - lastSensorReading >= SENSOR_INTERVAL)) {
    readSensors();
    sendDataToFirebase();
    lastSensorReading = millis();
  }
  
  // Handle serial commands
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    command.toUpperCase();
    handleCommand(command);
  }
  
  delay(1000);
}

// ========== WIFI CONNECTION ==========
void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    digitalWrite(LED_PIN, !digitalRead(LED_PIN)); // Blink while connecting
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    digitalWrite(LED_PIN, HIGH);
    Serial.println("\nWiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
  } else {
    wifiConnected = false;
    digitalWrite(LED_PIN, LOW);
    Serial.println("\nWiFi Connection Failed!");
  }
}

// ========== FIREBASE INITIALIZATION ==========
void initializeFirebase() {
  Serial.println("Initializing Firebase...");
  
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  if (Firebase.ready()) {
    firebaseReady = true;
    Serial.println("Firebase Connected!");
    registerDevice();
  } else {
    firebaseReady = false;
    Serial.println("Firebase Connection Failed!");
  }
}

// ========== SENSOR READING ==========
void readSensors() {
  Serial.println("Reading sensors...");
  digitalWrite(LED_PIN, HIGH);
  
  // Read raw analog values (0-4095 for ESP32)
  int nitrogenRaw = analogRead(NITROGEN_PIN);
  int phosphorusRaw = analogRead(PHOSPHORUS_PIN);
  int potassiumRaw = analogRead(POTASSIUM_PIN);
  
  // Convert to percentage (0-100%)
  nitrogen = map(nitrogenRaw, 0, 4095, 0, 100);
  phosphorus = map(phosphorusRaw, 0, 4095, 0, 100);
  potassium = map(potassiumRaw, 0, 4095, 0, 100);
  
  // Ensure values are within 0-100 range
  nitrogen = constrain(nitrogen, 0, 100);
  phosphorus = constrain(phosphorus, 0, 100);
  potassium = constrain(potassium, 0, 100);
  
  // Print readings
  Serial.println("--- Sensor Readings ---");
  Serial.println("Nitrogen: " + String(nitrogen, 1) + "%");
  Serial.println("Phosphorus: " + String(phosphorus, 1) + "%");
  Serial.println("Potassium: " + String(potassium, 1) + "%");
  Serial.println("----------------------");
  
  digitalWrite(LED_PIN, LOW);
}

// ========== SEND DATA TO FIREBASE ==========
void sendDataToFirebase() {
  if (!firebaseReady) {
    Serial.println("Firebase not ready!");
    return;
  }
  
  Serial.println("Sending data to Firebase...");
  
  // Get current timestamp
  unsigned long timestamp = WiFi.getTime();
  if (timestamp == 0) {
    timestamp = millis() / 1000; // Use millis as fallback
  }
  
  // Create JSON data
  DynamicJsonDocument doc(512);
  doc["nitrogen"] = nitrogen;
  doc["phosphorus"] = phosphorus;
  doc["potassium"] = potassium;
  doc["deviceId"] = deviceId;
  doc["timestamp"] = timestamp;
  doc["lastUpdate"] = timestamp;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Send current data
  if (Firebase.setString(firebaseData, "/soil_monitoring/current", jsonString)) {
    Serial.println("✓ Current data sent successfully");
    blinkLED(2, 100); // 2 quick blinks = success
  } else {
    Serial.println("✗ Failed to send current data");
    Serial.println("Error: " + firebaseData.errorReason());
  }
  
  // Send historical data
  String historyPath = "/soil_monitoring/history/" + String(timestamp);
  if (Firebase.setString(firebaseData, historyPath, jsonString)) {
    Serial.println("✓ Historical data sent successfully");
  } else {
    Serial.println("✗ Failed to send historical data");
  }
  
  // Update device status
  updateDeviceStatus();
}

// ========== DEVICE REGISTRATION ==========
void registerDevice() {
  Serial.println("Registering device...");
  
  DynamicJsonDocument deviceDoc(256);
  deviceDoc["deviceId"] = deviceId;
  deviceDoc["type"] = "ESP32_SoilMonitor";
  deviceDoc["location"] = "Field_001";
  deviceDoc["status"] = "online";
  deviceDoc["firmware"] = "1.0";
  deviceDoc["sensors"] = "NPK";
  deviceDoc["lastSeen"] = WiFi.getTime();
  
  String deviceJson;
  serializeJson(deviceDoc, deviceJson);
  
  String devicePath = "/devices/" + deviceId;
  if (Firebase.setString(firebaseData, devicePath, deviceJson)) {
    Serial.println("✓ Device registered successfully");
  } else {
    Serial.println("✗ Device registration failed");
  }
}

// ========== UPDATE DEVICE STATUS ==========
void updateDeviceStatus() {
  unsigned long currentTime = WiFi.getTime();
  if (currentTime == 0) {
    currentTime = millis() / 1000;
  }
  
  Firebase.setInt(firebaseData, "/devices/" + deviceId + "/lastSeen", currentTime);
  Firebase.setString(firebaseData, "/devices/" + deviceId + "/status", "online");
}

// ========== SERIAL COMMANDS ==========
void handleCommand(String command) {
  Serial.println("Command received: " + command);
  
  if (command == "READ") {
    readSensors();
  }
  else if (command == "SEND") {
    if (firebaseReady) {
      sendDataToFirebase();
    } else {
      Serial.println("Firebase not connected!");
    }
  }
  else if (command == "STATUS") {
    printStatus();
  }
  else if (command == "WIFI") {
    connectToWiFi();
    if (wifiConnected) {
      initializeFirebase();
    }
  }
  else if (command == "RESTART") {
    Serial.println("Restarting ESP32...");
    ESP.restart();
  }
  else if (command == "HELP") {
    Serial.println("Available commands:");
    Serial.println("READ - Read sensors");
    Serial.println("SEND - Send data to Firebase");
    Serial.println("STATUS - Show device status");
    Serial.println("WIFI - Reconnect WiFi");
    Serial.println("RESTART - Restart ESP32");
  }
  else {
    Serial.println("Unknown command. Type HELP for available commands.");
  }
}

// ========== STATUS DISPLAY ==========
void printStatus() {
  Serial.println("\n=== ESP32 Status ===");
  Serial.println("Device ID: " + deviceId);
  Serial.println("WiFi SSID: " + String(WIFI_SSID));
  Serial.println("WiFi Status: " + String(wifiConnected ? "Connected" : "Disconnected"));
  
  if (wifiConnected) {
    Serial.println("IP Address: " + WiFi.localIP().toString());
    Serial.println("Signal Strength: " + String(WiFi.RSSI()) + " dBm");
  }
  
  Serial.println("Firebase: " + String(firebaseReady ? "Connected" : "Disconnected"));
  Serial.println("Uptime: " + String(millis() / 1000) + " seconds");
  Serial.println("Free Memory: " + String(ESP.getFreeHeap()) + " bytes");
  Serial.println("Last Sensor Reading: " + String((millis() - lastSensorReading) / 1000) + " seconds ago");
  
  Serial.println("\nCurrent Sensor Values:");
  Serial.println("Nitrogen: " + String(nitrogen, 1) + "%");
  Serial.println("Phosphorus: " + String(phosphorus, 1) + "%");
  Serial.println("Potassium: " + String(potassium, 1) + "%");
  Serial.println("===================\n");
}

// ========== LED HELPER FUNCTION ==========
void blinkLED(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(delayMs);
    digitalWrite(LED_PIN, LOW);
    delay(delayMs);
  }
}

/*
  ========== SETUP INSTRUCTIONS ==========
  
  1. Install Required Libraries:
     - Go to Tools > Manage Libraries
     - Search and install "Firebase ESP32 Client" by Mobizt
     - Search and install "ArduinoJson" by Benoit Blanchon
  
  2. Board Configuration:
     - Tools > Board > ESP32 Arduino > ESP32 Dev Module
     - Tools > Upload Speed > 921600
     - Tools > CPU Frequency > 240MHz (WiFi/BT)
     - Tools > Flash Size > 4MB (32Mb)
  
  3. Update Configuration:
     - Change WIFI_SSID to your hotspot name
     - Change WIFI_PASSWORD to your hotspot password
     - FIREBASE_AUTH is already set for your project
  
  4. Wiring (if using external sensors):
     - Nitrogen Sensor → GPIO36
     - Phosphorus Sensor → GPIO39
     - Potassium Sensor → GPIO34
     - All sensors VCC → 3.3V
     - All sensors GND → GND
  
  5. Upload and Monitor:
     - Click Upload button
     - Open Serial Monitor (115200 baud)
     - Watch for connection messages
  
  ========== SERIAL COMMANDS ==========
  Open Serial Monitor and type these commands:
  - READ: Read sensors immediately
  - SEND: Send data to Firebase
  - STATUS: Show device status
  - WIFI: Reconnect to WiFi
  - RESTART: Restart ESP32
  - HELP: Show all commands
*/
