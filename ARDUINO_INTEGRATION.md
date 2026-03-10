# EcoSched Arduino Integration Guide

This guide explains how to connect a physical Arduino-based sensor (ESP8266 or ESP32) to the EcoSched system to monitor trash bin levels in real-time.

## Hardware Requirements

1.  **Microcontroller**: ESP8266 (e.g., NodeMCU) or ESP32.
2.  **Sensor**: HC-SR04 Ultrasonic Distance Sensor.
3.  **Power**: 5V USB Power supply.
4.  **Wiring**:
    *   **VCC** -> 5V (or 3.3V depending on sensor model)
    *   **GND** -> GND
    *   **Trig** -> Digital Pin (e.g., D1 / GPIO 5)
    *   **Echo** -> Digital Pin (e.g., D2 / GPIO 4)

## Firmware Setup

### 1. Install Libraries
Open the Arduino IDE and ensure you have the following libraries installed:
*   `ArduinoJson` (by Benoit Blanchon)
*   `ESP8266WiFi` (for ESP8266) or `WiFi` (for ESP32)
*   `ESP8266HTTPClient` or `HTTPClient`

### 2. Implementation Code (ESP8266 Example)

```cpp
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>

// --- Configuration ---
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Supabase details (find in Admin Dashboard config)
const char* supabaseUrl = "https://bfqktqtsjchbmopafgzf.supabase.co/rest/v1/bins?bin_id=eq.BIN-1189";
const char* apiKey = "sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31";

// Pin definitions
const int trigPin = 5; // D1
const int echoPin = 4; // D2

// Bin configuration
const int binHeightCm = 100; // Total height of the bin in cm

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    long duration;
    int distance;
    
    // Measure distance
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    duration = pulseIn(echoPin, HIGH);
    distance = duration * 0.034 / 2;

    // Calculate fill percentage
    // 0cm distance = 100% full, 100cm distance = 0% full
    int fillLevel = map(distance, binHeightCm, 0, 0, 100);
    fillLevel = constrain(fillLevel, 0, 100);

    Serial.printf("Distance: %dcm, Fill Level: %d%%\n", distance, fillLevel);

    // Send update to Supabase
    WiFiClientSecure client;
    client.setInsecure(); // For simplicity, though not recommended for production
    
    HTTPClient http;
    http.begin(client, supabaseUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", apiKey);
    http.addHeader("Authorization", String("Bearer ") + apiKey);

    StaticJsonDocument<128> doc;
    doc["fill_level"] = fillLevel;
    doc["updated_at"] = "now()"; // Supabase handles this via Postgres trigger or timestamp

    String requestBody;
    serializeJson(doc, requestBody);

    int httpResponseCode = http.PATCH(requestBody);

    if (httpResponseCode > 0) {
      Serial.print("Update sent! Response: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("Error sending update: ");
      Serial.println(httpResponseCode);
    }

    http.end();
  }

  // Frequency of updates (e.g., every 10 minutes)
  delay(600000); 
}
```

## How it Works

1.  **HTTP PATCH**: The Arduino sends a secured HTTP PATCH request to the Supabase REST API endpoint for the specific `bin_id`.
2.  **API Authorization**: It uses the same `anon` key used by the Admin Dashboard.
3.  **Postgres Trigger**: When the `fill_level` is updated via this API call, the database trigger we created in `supabase_schema.sql` automatically checks the value and sends notifications to administrators if the bin is full.
