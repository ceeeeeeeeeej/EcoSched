#ifndef CONFIG_H
#define CONFIG_H

// WiFi Configuration
static const char *SSID = "LANSADERAS";
static const char *PASSWORD = "Cjhay2003";

// Supabase Configuration
static const char *SUPABASE_URL = "https://bfqktqtsjchbmopafgzf.supabase.co";
static const char *SUPABASE_API_KEY =
    "sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31";

// GPS Configuration
static const int GPS_RX_PIN = 5; // D1 (GPIO 5) - Connect to GPS TX
static const int GPS_TX_PIN = 4; // D2 (GPIO 4) - Connect to GPS RX
static const int GPS_BAUD_RATE = 9600;

// Target Bin Configuration
static const char *BIN_ID = "BIN-1189";
static const char *SUPABASE_REST_URL =
    "https://bfqktqtsjchbmopafgzf.supabase.co/rest/v1/bins";

#endif
