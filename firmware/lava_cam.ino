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
  Serial.println();

  pinMode(LED_GPIO_NUM, OUTPUT);
  digitalWrite(LED_GPIO_NUM, LOW); // Start off

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    // Blink to indicate connecting
    digitalWrite(LED_GPIO_NUM, !digitalRead(LED_GPIO_NUM));
  }
  digitalWrite(LED_GPIO_NUM, LOW); // Off when connected
  Serial.println("");
  Serial.println("WiFi connected");

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
    config.frame_size = FRAMESIZE_UXGA; // 1600x1200
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  // Camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }

  Serial.println("Camera Ready!");

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
  // Deep sleep or delay
  Serial.println("Waiting 60 seconds before next capture...");
  delay(60000);
  takeDataAndUpload();
}

void takeDataAndUpload() {
  Serial.println("Taking picture...");
  digitalWrite(LED_GPIO_NUM, HIGH); // Flash on for photo (and status)

  camera_fb_t *fb = NULL;

  // Discard first few frames to allow auto-exposure to settle
  for (int i = 0; i < 3; i++) {
    fb = esp_camera_fb_get();
    esp_camera_fb_return(fb);
    delay(50);
  }

  fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    digitalWrite(LED_GPIO_NUM, LOW);
    return;
  }

  digitalWrite(LED_GPIO_NUM, LOW); // Flash off
  Serial.printf("Picture taken! Size: %d bytes\n", fb->len);

  // Basic Upload Logic (Placeholder for S3 PUT)
  WiFiClientSecure client;
  client.setInsecure(); // Don't validate certificate for hackathon speed/ease

  // S3 Bucket URL construction
  String host =
      String(AWS_BUCKET_NAME) + ".s3." + String(AWS_REGION) + ".amazonaws.com";
  String filename = "lava_" + String(millis()) + ".jpg";

  Serial.println("Connecting to " + host);

  if (client.connect(host.c_str(), 443)) {
    Serial.println("Connected to S3. Uploading...");

    // Note: Use a public-write bucket policy or pre-signed URL for this to work
    // without AWS auth headers. For proper auth, you need to calculate SigV4
    // which is heavy for ESP32 without a library. Recommendation: Make the
    // bucket public-write for the hackathon duration ONLY.

    client.println("PUT /" + filename + " HTTP/1.1");
    client.println("Host: " + host);
    client.println("Content-Type: image/jpeg");
    client.println("Content-Length: " + String(fb->len));
    client.println("Connection: close");
    client.println();

    uint8_t *fbBuf = fb->buf;
    size_t fbLen = fb->len;
    for (size_t n = 0; n < fbLen; n = n + 1024) {
      if (n + 1024 < fbLen) {
        client.write(fbBuf, 1024);
        fbBuf += 1024;
      } else if (fbLen % 1024 > 0) {
        size_t remainder = fbLen % 1024;
        client.write(fbBuf, remainder);
      }
    }

    while (client.connected()) {
      String line = client.readStringUntil('\n');
      if (line == "\r") {
        Serial.println("Headers received");
        break;
      }
    }
    Serial.println("Upload complete!");
    client.stop();
  } else {
    Serial.println("Connection to S3 failed");
  }

  esp_camera_fb_return(fb);
}
