#include "esp_camera.h"
#include "secrets.h"
#include "time.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <mbedtls/md.h>
#include <mbedtls/sha256.h>

// --- CAMERA PIN CONFIG ---
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
#define LED_GPIO_NUM 4

// --- AWS CONFIG ---
const char *ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 0; // UTC time
const int daylightOffset_sec = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("\n--- SYSTEM START v2.0 (Direct S3 Auth) ---");

  pinMode(LED_GPIO_NUM, OUTPUT);
  digitalWrite(LED_GPIO_NUM, LOW);

  // 1. WiFi
  Serial.printf("Connecting to %s ", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    digitalWrite(LED_GPIO_NUM, !digitalRead(LED_GPIO_NUM));
  }
  digitalWrite(LED_GPIO_NUM, LOW);
  Serial.println("\n[SUCCESS] WiFi connected");

  // 2. Time Sync (Critical for AWS SigV4)
  Serial.println("Syncing Time...");
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  struct tm timeinfo;
  while (!getLocalTime(&timeinfo)) {
    Serial.print(".");
    delay(100);
  }
  Serial.println("\n[SUCCESS] Time Synced");

  // 3. Camera Init
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
    config.frame_size = FRAMESIZE_UXGA;
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("Camera Init Failed");
    return;
  }
  Serial.println("Camera Ready");

  takeAndUploadDetails();
}

void loop() {
  Serial.println("Waiting 60s...");
  delay(60000);
  takeAndUploadDetails();
}

// --- CRYPTO HELPERS ---

String sha256(String input) {
  byte hash[32];
  mbedtls_sha256_context ctx;
  mbedtls_sha256_init(&ctx);
  mbedtls_sha256_starts(&ctx, 0);
  mbedtls_sha256_update(&ctx, (const unsigned char *)input.c_str(),
                        input.length());
  mbedtls_sha256_finish(&ctx, hash);
  mbedtls_sha256_free(&ctx);

  String result = "";
  for (int i = 0; i < 32; i++) {
    if (hash[i] < 0x10)
      result += "0";
    result += String(hash[i], HEX);
  }
  return result;
}

String sha256_buf(uint8_t *buf, size_t len) {
  byte hash[32];
  mbedtls_sha256_context ctx;
  mbedtls_sha256_init(&ctx);
  mbedtls_sha256_starts(&ctx, 0);
  mbedtls_sha256_update(&ctx, buf, len);
  mbedtls_sha256_finish(&ctx, hash);
  mbedtls_sha256_free(&ctx);

  String result = "";
  for (int i = 0; i < 32; i++) {
    if (hash[i] < 0x10)
      result += "0";
    result += String(hash[i], HEX);
  }
  return result;
}

void hmac_sha256(const char *key, size_t keylen, const char *data,
                 size_t datalen, unsigned char *output) {
  mbedtls_md_context_t ctx;
  mbedtls_md_type_t md_type = MBEDTLS_MD_SHA256;

  mbedtls_md_init(&ctx);
  mbedtls_md_setup(&ctx, mbedtls_md_info_from_type(md_type), 1);
  mbedtls_md_hmac_starts(&ctx, (const unsigned char *)key, keylen);
  mbedtls_md_hmac_update(&ctx, (const unsigned char *)data, datalen);
  mbedtls_md_hmac_finish(&ctx, output);
  mbedtls_md_free(&ctx);
}

// --- UPLOAD LOGIC ---

void takeAndUploadDetails() {
  Serial.println("Taking Picture...");
  digitalWrite(LED_GPIO_NUM, HIGH);

  camera_fb_t *fb = NULL;
  // Cleanup buffer
  esp_camera_fb_return(esp_camera_fb_get());
  delay(100);

  fb = esp_camera_fb_get();
  digitalWrite(LED_GPIO_NUM, LOW);

  if (!fb) {
    Serial.println("Capture failed");
    return;
  }
  Serial.printf("Size: %d bytes\n", fb->len);

  // 1. Dates
  struct tm timeinfo;
  getLocalTime(&timeinfo);
  char amzDate[20];  // YYYYMMDDTHHMMSSZ
  char dateStamp[9]; // YYYYMMDD
  strftime(amzDate, 20, "%Y%m%dT%H%M%SZ", &timeinfo);
  strftime(dateStamp, 9, "%Y%m%d", &timeinfo);

  // 2. Resource
  String filename = "lava_" + String(millis()) + ".jpg";
  String canonical_uri = "/" + filename;

  // 3. Payload Hash
  String payload_hash = sha256_buf(fb->buf, fb->len);

  // 4. Canonical Request
  // Method
  // CanonicalURI
  // CanonicalQueryString
  // CanonicalHeaders
  // SignedHeaders
  // PayloadHash
  String host =
      String(AWS_BUCKET_NAME) + ".s3." + String(AWS_REGION) + ".amazonaws.com";

  // NOTE: Headers must be sorted, lowercase
  String canonical_headers = "host:" + host +
                             "\nx-amz-content-sha256:" + payload_hash +
                             "\nx-amz-date:" + String(amzDate) + "\n";
  String signed_headers = "host;x-amz-content-sha256;x-amz-date";

  String canonical_request = "PUT\n" + canonical_uri + "\n\n" +
                             canonical_headers + "\n" + signed_headers + "\n" +
                             payload_hash;

  // 5. String to Sign
  String algorithm = "AWS4-HMAC-SHA256";
  String credential_scope =
      String(dateStamp) + "/" + String(AWS_REGION) + "/s3/aws4_request";
  String string_to_sign = algorithm + "\n" + String(amzDate) + "\n" +
                          credential_scope + "\n" + sha256(canonical_request);

  // 6. Sign
  byte kSecret[64];
  byte kDate[32];
  byte kRegion[32];
  byte kService[32];
  byte kSigning[32];
  byte signature[32];

  String secretStr = "AWS4" + String(AWS_SECRET_KEY);
  hmac_sha256(secretStr.c_str(), secretStr.length(), dateStamp,
              strlen(dateStamp), kDate);
  hmac_sha256((char *)kDate, 32, AWS_REGION, strlen(AWS_REGION), kRegion);
  hmac_sha256((char *)kRegion, 32, "s3", 2, kService);
  hmac_sha256((char *)kService, 32, "aws4_request", 12, kSigning);
  hmac_sha256((char *)kSigning, 32, string_to_sign.c_str(),
              string_to_sign.length(), signature);

  String signatureStr = "";
  for (int i = 0; i < 32; i++) {
    if (signature[i] < 0x10)
      signatureStr += "0";
    signatureStr += String(signature[i], HEX);
  }

  String authorization_header =
      algorithm + " Credential=" + String(AWS_ACCESS_KEY) + "/" +
      credential_scope + ", SignedHeaders=" + signed_headers +
      ", Signature=" + signatureStr;

  // 7. Send Request
  WiFiClientSecure client;
  client.setInsecure();

  if (client.connect(host.c_str(), 443)) {
    Serial.println("Uploading...");

    client.print("PUT " + canonical_uri + " HTTP/1.1\r\n");
    client.print("Host: " + host + "\r\n");
    client.print("x-amz-date: " + String(amzDate) + "\r\n");
    client.print("x-amz-content-sha256: " + payload_hash + "\r\n");
    client.print("Authorization: " + authorization_header + "\r\n");
    client.print("Content-Length: " + String(fb->len) + "\r\n\r\n");

    // Send data in chunks
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

    // Read Response
    while (client.connected()) {
      String line = client.readStringUntil('\n');
      if (line.startsWith("HTTP/1.1"))
        Serial.println("Status: " + line);
      if (line == "\r")
        break;
    }
  } else {
    Serial.println("Connect Failed");
  }

  esp_camera_fb_return(fb);
}
