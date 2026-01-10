#include "esp_camera.h"
#include "secrets.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>

// CAMERA_MODEL_AI_THINKER
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

#define LED_GPIO_NUM                                                           \
  4 // Flash Light on ESP32-CAM (or 33 for onboard built-in LED on some boards)

void setup() {
  Serial.begin(115200);
  Serial.println("--- SYSTEM START ---");
  Serial.println("1. Setting up LEDs...");

  pinMode(LED_GPIO_NUM, OUTPUT);
  digitalWrite(LED_GPIO_NUM, LOW); // Start off

  Serial.println("2. Starting WiFi Connection to: " + String(WIFI_SSID));
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retryCount = 0;
  while (WiFi.status() != WL_CONNECTED &&
         retryCount < 40) { // Increased timeout to 20s
    delay(500);
    Serial.print(".");
    if (retryCount % 10 == 0)
      Serial.println(" (Still connecting...)");
    // Blink to indicate connecting
    digitalWrite(LED_GPIO_NUM, !digitalRead(LED_GPIO_NUM));
    retryCount++;
  }

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("\n[ERROR] WiFi Connect Failed! Status: " +
                   String(WiFi.status()));
    Serial.println("Common codes: 1=NO_SSID, 4=CONNECT_FAIL, 6=NO_PASS");
    return; // Stop here if no wifi
  } else {
    digitalWrite(LED_GPIO_NUM, LOW);
    Serial.println("\n[SUCCESS] WiFi connected! IP: " +
                   WiFi.localIP().toString());
  }

  Serial.println("3. Configuring Camera...");
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if (psramFound()) {
    Serial.println("  - PSRAM found, using UXGA");
    config.frame_size = FRAMESIZE_UXGA; // 1600x1200
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    Serial.println("  - No PSRAM, using SVGA");
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  // Camera init
  Serial.println("4. Initializing Camera Driver...");
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("[ERROR] Camera Init Failed: 0x%x\n", err);
    return;
  }

  Serial.println("[SUCCESS] Camera Ready!");

  // Indicate ready with 3 quick blinks
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_GPIO_NUM, HIGH);
    delay(100);
    digitalWrite(LED_GPIO_NUM, LOW);
    delay(100);
  }

  takeDataAndUpload();
}

void loop() {
  Serial.println("\n--- LOOP START ---");
  Serial.println("Waiting 60 seconds...");
  delay(60000);
  takeDataAndUpload();
}

void takeDataAndUpload() {
  Serial.println("STEP: Taking Picture");
  digitalWrite(LED_GPIO_NUM, HIGH); // Flash on

  camera_fb_t *fb = NULL;

  // Discard frames
  Serial.println("  - Warming up sensor...");
  for (int i = 0; i < 3; i++) {
    fb = esp_camera_fb_get();
    esp_camera_fb_return(fb);
    delay(50);
  }

  Serial.println("  - Capturing frame...");
  fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("[ERROR] Capture failed");
    digitalWrite(LED_GPIO_NUM, LOW);
    return;
  }

  digitalWrite(LED_GPIO_NUM, LOW); // Flash off
  Serial.printf("[SUCCESS] Picture taken! Size: %d bytes\n", fb->len);

  // S3 Upload
  WiFiClientSecure client;
  client.setInsecure();

  String host =
      String(AWS_BUCKET_NAME) + ".s3." + String(AWS_REGION) + ".amazonaws.com";
  String filename = "lava_" + String(millis()) + ".jpg";

  Serial.println("STEP: Uploading to " + host);
  Serial.println("  - Filename: " + filename);

  if (client.connect(host.c_str(), 443)) {
    Serial.println("  - [SUCCESS] Connected to server");

    Serial.println("  - Sending Headers...");
    client.println("PUT /" + filename + " HTTP/1.1");
    client.println("Host: " + host);
    client.println("Content-Type: image/jpeg");
    client.println("Content-Length: " + String(fb->len));
    client.println("Connection: close");
    client.println();

    Serial.println("  - Sending Body...");
    uint8_t *fbBuf = fb->buf;
    size_t fbLen = fb->len;
    size_t sent = 0;
    for (size_t n = 0; n < fbLen; n = n + 1024) {
      if (n + 1024 < fbLen) {
        client.write(fbBuf, 1024);
        fbBuf += 1024;
        sent += 1024;
      } else if (fbLen % 1024 > 0) {
        size_t remainder = fbLen % 1024;
        client.write(fbBuf, remainder);
        sent += remainder;
      }
      // Log progress every 10k
      if (sent % 10240 == 0)
        Serial.print(".");
    }
    Serial.println("\n  - Body sent.");

    Serial.println("  - Waiting for response...");
    while (client.connected()) {
      String line = client.readStringUntil('\n');
      if (line == "\r") {
        Serial.println("  - [RESPONSE] Headers received.");
        break;
      }
      //      Serial.println("    > " + line); // Uncomment to see full headers
    }
    Serial.println("[SUCCESS] Upload procedure finished.");
    client.stop();
  } else {
    Serial.println("[ERROR] Connection to S3 failed!");
  }

  esp_camera_fb_return(fb);
}
