#include <ESP8266HTTPClient.h>
#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>


// -------- PIN DEFINITIONS --------
#define TRIG 5  // D1
#define ECHO 14 // D5

#define WIFI_LED 13 // D7

#define GREEN_LED 4   // D2
#define YELLOW_LED 16 // D0
#define RED_LED 2     // D4

// -------- WIFI --------
const char *ssid = "PLDTHOMEFIBRa25gd";
const char *password = "PLDTWIFIAs3rY";

// -------- SUPABASE DETAILS --------
const char *supabaseUrl =
    "https://bfqktqtsjchbmopafgzf.supabase.co/rest/v1/bins?bin_id=eq.BIN-1189";
const char *supabaseKey = "sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31";

// -------- VARIABLES --------
long duration;
float distance;
float lastValidDistance = 44;
float binHeight = 44.0;
float fillLevel;

// -------- DISTANCE FUNCTION --------
float readDistance() {

  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);

  duration = pulseIn(ECHO, HIGH, 40000);

  if (duration == 0)
    return lastValidDistance;

  float d = (duration * 0.0343) / 2;

  if (d > 2 && d < 60) {
    lastValidDistance = d;
    return d;
  }

  return lastValidDistance;
}

// -------- LED CONTROL --------
void setBinLED(bool g, bool y, bool r) {
  digitalWrite(GREEN_LED, g);
  digitalWrite(YELLOW_LED, y);
  digitalWrite(RED_LED, r);
}

// -------- SEND TO ADMIN DASHBOARD --------
void sendToAdminDashboard(int currentFillLevel) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure(); // No SSL certificate validation

    HTTPClient http;
    http.begin(client, supabaseUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", String("Bearer ") + String(supabaseKey));

    // Create JSON payload
    String requestBody = "{\"fill_level\": " + String(currentFillLevel) + "}";

    int httpResponseCode = http.PATCH(requestBody);

    if (httpResponseCode > 0) {
      Serial.print("Data sent to Admin Dashboard. HTTP Response: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("Error sending data. HTTP Error: ");
      Serial.println(httpResponseCode);
    }

    http.end();
  } else {
    Serial.println("WiFi not connected. Cannot send data.");
  }
}

// -------- SETUP --------
void setup() {

  Serial.begin(115200);

  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);

  pinMode(WIFI_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(YELLOW_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);

  digitalWrite(WIFI_LED, LOW);
  setBinLED(LOW, LOW, LOW);

  WiFi.begin(ssid, password);
  Serial.print("Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    digitalWrite(WIFI_LED, HIGH);
    delay(250);
    digitalWrite(WIFI_LED, LOW);
    delay(250);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected!");
  digitalWrite(WIFI_LED, HIGH);
}

// -------- LOOP --------
void loop() {

  distance = readDistance();

  fillLevel = ((binHeight - distance) / binHeight) * 100;
  fillLevel = constrain(fillLevel, 0, 100);

  Serial.println("----------------------");

  if (fillLevel < 20) {

    Serial.println("Status: NOT FULL");
    setBinLED(HIGH, LOW, LOW);

  } else if (fillLevel < 60) {

    Serial.println("Status: ALMOST FULL");
    setBinLED(LOW, HIGH, LOW);

  } else {

    Serial.println("Status: FULL");
    setBinLED(LOW, LOW, HIGH);
  }

  // Send the data
  sendToAdminDashboard((int)fillLevel);

  delay(2000);
}