/*
  Soil Monitoring Sensor for Eggplant Farming
  
  This Arduino sketch reads NPK (Nitrogen, Phosphorus, Potassium) values
  from soil sensors and sends the data to a Flutter app via serial communication.
  
  Hardware Requirements:
  - Arduino Uno/Nano/ESP32
  - NPK Soil Sensor (or individual N, P, K sensors)
  - Optional: pH sensor, moisture sensor, temperature sensor
  
  Wiring:
  - NPK Sensor VCC -> 5V (or 3.3V for ESP32)
  - NPK Sensor GND -> GND
  - NPK Sensor Data -> A0 (Nitrogen)
  - Additional sensors -> A1 (Phosphorus), A2 (Potassium)
  
  Serial Communication:
  - Baud Rate: 9600
  - Data Format: JSON {"nitrogen": 75.5, "phosphorus": 60.2, "potassium": 85.1}
  - Alternative Format: CSV "75.5,60.2,85.1"
*/

// Pin definitions
#define NITROGEN_PIN A0
#define PHOSPHORUS_PIN A1
#define POTASSIUM_PIN A2
#define LED_PIN 13

// Sensor calibration values (adjust based on your sensors)
#define NITROGEN_MIN 0
#define NITROGEN_MAX 1023
#define PHOSPHORUS_MIN 0
#define PHOSPHORUS_MAX 1023
#define POTASSIUM_MIN 0
#define POTASSIUM_MAX 1023

// Timing variables
unsigned long lastReading = 0;
const unsigned long READING_INTERVAL = 5000; // Read every 5 seconds
bool autoMode = true;

// Sensor values
float nitrogenLevel = 0.0;
float phosphorusLevel = 0.0;
float potassiumLevel = 0.0;

void setup() {
  // Initialize serial communication
  Serial.begin(9600);
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(NITROGEN_PIN, INPUT);
  pinMode(PHOSPHORUS_PIN, INPUT);
  pinMode(POTASSIUM_PIN, INPUT);
  
  // Startup indication
  digitalWrite(LED_PIN, HIGH);
  delay(1000);
  digitalWrite(LED_PIN, LOW);
  
  Serial.println("Soil Monitoring Sensor Initialized");
  Serial.println("Commands: READ_SENSORS, CALIBRATE, AUTO_ON, AUTO_OFF, PING");
}

void loop() {
  // Check for serial commands
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    handleCommand(command);
  }
  
  // Auto-read sensors if enabled
  if (autoMode && (millis() - lastReading >= READING_INTERVAL)) {
    readAndSendSensorData();
    lastReading = millis();
  }
  
  delay(100);
}

void handleCommand(String command) {
  if (command == "READ_SENSORS") {
    readAndSendSensorData();
  }
  else if (command == "CALIBRATE") {
    calibrateSensors();
  }
  else if (command == "AUTO_ON") {
    autoMode = true;
    Serial.println("Auto mode enabled");
  }
  else if (command == "AUTO_OFF") {
    autoMode = false;
    Serial.println("Auto mode disabled");
  }
  else if (command == "PING") {
    Serial.println("PONG - Arduino is connected");
  }
  else if (command == "STATUS") {
    sendStatus();
  }
  else {
    Serial.println("Unknown command: " + command);
  }
}

void readAndSendSensorData() {
  // Blink LED to indicate reading
  digitalWrite(LED_PIN, HIGH);
  
  // Read raw sensor values
  int nitrogenRaw = analogRead(NITROGEN_PIN);
  int phosphorusRaw = analogRead(PHOSPHORUS_PIN);
  int potassiumRaw = analogRead(POTASSIUM_PIN);
  
  // Convert to percentage (0-100%)
  nitrogenLevel = mapFloat(nitrogenRaw, NITROGEN_MIN, NITROGEN_MAX, 0.0, 100.0);
  phosphorusLevel = mapFloat(phosphorusRaw, PHOSPHORUS_MIN, PHOSPHORUS_MAX, 0.0, 100.0);
  potassiumLevel = mapFloat(potassiumRaw, POTASSIUM_MIN, POTASSIUM_MAX, 0.0, 100.0);
  
  // Constrain values to 0-100 range
  nitrogenLevel = constrain(nitrogenLevel, 0.0, 100.0);
  phosphorusLevel = constrain(phosphorusLevel, 0.0, 100.0);
  potassiumLevel = constrain(potassiumLevel, 0.0, 100.0);
  
  // Send data in JSON format
  sendJSONData();
  
  // Alternative: Send data in CSV format
  // sendCSVData();
  
  digitalWrite(LED_PIN, LOW);
}

void sendJSONData() {
  Serial.print("{\"nitrogen\": ");
  Serial.print(nitrogenLevel, 1);
  Serial.print(", \"phosphorus\": ");
  Serial.print(phosphorusLevel, 1);
  Serial.print(", \"potassium\": ");
  Serial.print(potassiumLevel, 1);
  Serial.println("}");
}

void sendCSVData() {
  Serial.print(nitrogenLevel, 1);
  Serial.print(",");
  Serial.print(phosphorusLevel, 1);
  Serial.print(",");
  Serial.println(potassiumLevel, 1);
}

void calibrateSensors() {
  Serial.println("Starting sensor calibration...");
  
  // Blink LED during calibration
  for (int i = 0; i < 10; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
    delay(200);
  }
  
  // Read multiple samples for calibration
  long nitrogenSum = 0, phosphorusSum = 0, potassiumSum = 0;
  int samples = 50;
  
  for (int i = 0; i < samples; i++) {
    nitrogenSum += analogRead(NITROGEN_PIN);
    phosphorusSum += analogRead(PHOSPHORUS_PIN);
    potassiumSum += analogRead(POTASSIUM_PIN);
    delay(100);
  }
  
  // Calculate averages
  int nitrogenAvg = nitrogenSum / samples;
  int phosphorusAvg = phosphorusSum / samples;
  int potassiumAvg = potassiumSum / samples;
  
  Serial.println("Calibration complete:");
  Serial.println("Nitrogen baseline: " + String(nitrogenAvg));
  Serial.println("Phosphorus baseline: " + String(phosphorusAvg));
  Serial.println("Potassium baseline: " + String(potassiumAvg));
  
  // You can store these values in EEPROM for persistent calibration
  // EEPROM.write(0, nitrogenAvg);
  // EEPROM.write(1, phosphorusAvg);
  // EEPROM.write(2, potassiumAvg);
}

void sendStatus() {
  Serial.println("=== Soil Monitoring Sensor Status ===");
  Serial.println("Auto Mode: " + String(autoMode ? "ON" : "OFF"));
  Serial.println("Last Reading:");
  Serial.println("  Nitrogen: " + String(nitrogenLevel, 1) + "%");
  Serial.println("  Phosphorus: " + String(phosphorusLevel, 1) + "%");
  Serial.println("  Potassium: " + String(potassiumLevel, 1) + "%");
  Serial.println("Uptime: " + String(millis() / 1000) + " seconds");
  Serial.println("=====================================");
}

// Helper function to map float values
float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

/*
  Additional Features You Can Add:

  1. WiFi Connectivity (ESP32/ESP8266):
     - Send data directly to Firebase
     - Create a web server for configuration
  
  2. Additional Sensors:
     - pH sensor (A3)
     - Soil moisture sensor (A4)
     - Temperature sensor (A5)
  
  3. Data Logging:
     - SD card module for local storage
     - EEPROM for sensor calibration values
  
  4. Power Management:
     - Sleep modes for battery operation
     - Solar panel charging circuit
  
  5. Actuators:
     - Relay control for irrigation
     - Servo motor for sample collection
  
  Example Enhanced JSON Output:
  {
    "nitrogen": 75.5,
    "phosphorus": 60.2,
    "potassium": 85.1,
    "ph": 6.8,
    "moisture": 45.3,
    "temperature": 25.7,
    "timestamp": 1699123456
  }
*/
