#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>

// -------- PIN DEFINITIONS --------
#define TRIG 5
#define ECHO 14

#define WIFI_LED 13
#define GREEN_LED 4
#define RED_LED 2

// -------- WIFI --------
const char* ssid = "Pentin-2.4G";
const char* password = "08290314pentin";

// -------- SUPABASE --------
const char* supabaseUrl = "https://bfqktqtsjchbmopafgzf.supabase.co";
const char* supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo";

// -------- VARIABLES --------
float lastValidDistance = 65.0;
float binHeight = 105.0;

// -------- TIMERS --------
unsigned long lastSendTime = 0;
unsigned long lastReadTime = 0;
unsigned long lastFullDetectTime = 0;

// -------- STATE --------
bool isRed = false;

// -------- READ DISTANCE --------
float readDistance() {

  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);

  long dur = pulseIn(ECHO, HIGH, 20000);

  if (dur == 0) return binHeight;

  float d = (dur * 0.0343) / 2;

  if (d > 2 && d < 120) {
    lastValidDistance = d;
    return d;
  }

  return binHeight;
}

// -------- LED CONTROL --------
void setBinLED(bool redOn) {
  digitalWrite(RED_LED, redOn);
  digitalWrite(GREEN_LED, !redOn);
}

// -------- SEND TO SUPABASE --------
void sendToSupabase(float distance, bool isRed) {

  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient https;

  String url = String(supabaseUrl) + "/rest/v1/bins?bin_id=eq.ECO-VIC-24";
  https.begin(client, url);

  https.addHeader("Content-Type", "application/json");
  https.addHeader("apikey", supabaseKey);
  https.addHeader("Authorization", "Bearer " + String(supabaseKey));
  https.addHeader("Prefer", "return=minimal");

  // -------- BIN STATUS --------
  String binStatus;
  if (isRed) {
    binStatus = "full";
  } else {
    binStatus = "normal";
  }

  // -------- JSON --------
  String jsonBody = "{";
  jsonBody += "\"distance\":" + String(distance, 2) + ",";
  jsonBody += "\"status\":\"online\",";
  jsonBody += "\"bin_status\":\"" + binStatus + "\"";
  jsonBody += "}";

  https.PATCH(jsonBody);
  https.end();
}

// -------- SETUP --------
void setup() {

  Serial.begin(115200);

  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);

  pinMode(WIFI_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);

  digitalWrite(WIFI_LED, LOW);
  setBinLED(false);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    digitalWrite(WIFI_LED, HIGH);
    delay(200);
    digitalWrite(WIFI_LED, LOW);
    delay(200);
  }

  digitalWrite(WIFI_LED, HIGH);
}

// -------- LOOP --------
void loop() {

  if (millis() - lastReadTime > 80) {
    lastReadTime = millis();

    float distance = readDistance();

    Serial.print("Distance: ");
    Serial.println(distance);

    // -------- FULL HOLD LOGIC --------
    if (distance < 60) {
      isRed = true;
      lastFullDetectTime = millis();
    }
    else {
      if (millis() - lastFullDetectTime > 10000) {
        isRed = false;
      }
    }

    setBinLED(isRed);

    // -------- HEARTBEAT SEND --------
    if (millis() - lastSendTime > 5000) {
      lastSendTime = millis();
      sendToSupabase(distance, isRed);
    }
  }
}