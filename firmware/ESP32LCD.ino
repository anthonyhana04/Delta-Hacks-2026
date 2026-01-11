#include <TFT_eSPI.h>
#include <SPI.h>
#include <HardwareSerial.h>

// ---------- TFT ----------
TFT_eSPI tft = TFT_eSPI();  // Uses TFT_eSPI User_Setup.h pins

// ---------- UART (WROOM) ----------
static const uint32_t UART_BAUD = 115200;
static const int UART_RX_PIN = 16; // WROOM RX  <- CAM TX
static const int UART_TX_PIN = 17; // WROOM TX  -> CAM RX (optional)
HardwareSerial Link(2);

// ---------- UI state ----------
enum UiState {
  UI_BOOT,
  UI_WIFI_CONNECTING,
  UI_WIFI_OK,
  UI_TIME_SYNC,
  UI_COUNTDOWN,
  UI_CAPTURE,
  UI_UPLOAD,
  UI_DONE,
  UI_WAIT_NEXT,
  UI_FAIL
};

UiState ui = UI_BOOT;
int countdownVal = -1;
String lastIP = "";
String lastKey = "";
int lastSize = 0;

// ---------- Post-upload countdown ----------
unsigned long waitStartMillis = 0;
int waitSecondsRemaining = 60;
int cloudOffset = 0;  // For animated clouds
int lastCloudUpdate = 0;  // Track last cloud redraw

// ---------- Color Palette ----------
#define COLOR_BG        0x0841      // Dark blue-gray
#define COLOR_SKY       0x2124      // Dark purple/blue for lava lamp background
#define COLOR_CARD_BG   0x1082      // Lighter card background
#define COLOR_PRIMARY   0x05FF      // Bright cyan
#define COLOR_SUCCESS   0x07E0      // Bright green
#define COLOR_WARNING   0xFD20      // Orange
#define COLOR_DANGER    0xF800      // Red
#define COLOR_TEXT      0xFFFF      // White
#define COLOR_TEXT_DIM  0x8410      // Gray
#define COLOR_ACCENT    0x07FF      // Cyan
#define COLOR_BLOB1     0xF81F      // Magenta blob
#define COLOR_BLOB2     0x07FF      // Cyan blob
#define COLOR_BLOB3     0xFD20      // Orange blob
#define COLOR_BLOB4     0xF81F      // Magenta blob (darker)
#define COLOR_BLOB5     0x07E0      // Green blob

// ---------- helpers ----------
String getValueAfter(const String &s, const String &key) {
  int idx = s.indexOf(key);
  if (idx < 0) return "";
  idx += key.length();
  int end = s.indexOf(',', idx);
  if (end < 0) end = s.length();
  return s.substring(idx, end);
}

int getTextWidth(String text, int size) {
  return text.length() * 6 * size;
}

void drawCard(int x, int y, int w, int h, uint16_t color) {
  tft.fillRoundRect(x, y, w, h, 8, color);
}

void drawProgressBar(int x, int y, int w, int h, int percent, uint16_t color) {
  tft.fillRoundRect(x, y, w, h, 4, COLOR_CARD_BG);
  if (percent > 0) {
    int fillW = (w * percent) / 100;
    tft.fillRoundRect(x, y, fillW, h, 4, color);
  }
}

void drawSpinner(int x, int y, int r, uint16_t color) {
  static int angle = 0;
  for (int i = 0; i < 12; i++) {
    int alpha = (i * 30 + angle) % 360;
    float rad = alpha * 3.14159 / 180.0;
    int x1 = x + r * cos(rad);
    int y1 = y + r * sin(rad);
    int x2 = x + (r - 5) * cos(rad);
    int y2 = y + (r - 5) * sin(rad);
    uint16_t c = (i < 3) ? color : COLOR_TEXT_DIM;
    tft.drawLine(x1, y1, x2, y2, c);
  }
  angle += 30;
}

void drawWifiWaves(int x, int y, uint16_t color) {
  tft.fillCircle(x, y + 8, 3, color);
  tft.drawCircle(x, y + 8, 8, color);
  tft.drawCircle(x, y + 8, 8, color);
  tft.drawCircle(x, y + 8, 14, color);
  tft.drawCircle(x, y + 8, 14, color);
  tft.drawCircle(x, y + 8, 20, color);
  tft.drawCircle(x, y + 8, 20, color);
}

void drawCamera(int x, int y, uint16_t color) {
  // Camera body
  tft.fillRoundRect(x, y + 8, 40, 28, 4, color);
  // Lens
  tft.fillCircle(x + 25, y + 22, 10, COLOR_BG);
  tft.drawCircle(x + 25, y + 22, 10, color);
  tft.drawCircle(x + 25, y + 22, 7, color);
  // Viewfinder
  tft.fillRoundRect(x + 5, y, 15, 10, 2, color);
  // Flash
  tft.fillRect(x + 35, y + 2, 4, 6, color);
}

void drawCloud(int x, int y, uint16_t color) {
  tft.fillCircle(x + 15, y + 15, 10, color);
  tft.fillCircle(x + 30, y + 12, 12, color);
  tft.fillCircle(x + 45, y + 15, 10, color);
  tft.fillRect(x + 15, y + 15, 30, 15, color);
  // Upload arrow
  tft.fillTriangle(x + 30, y + 35, x + 25, y + 25, x + 35, y + 25, COLOR_BG);
  tft.fillRect(x + 27, y + 25, 6, 12, COLOR_BG);
}

void drawCheckmark(int x, int y, uint16_t color) {
  tft.fillCircle(x + 20, y + 20, 20, color);
  tft.drawLine(x + 10, y + 20, x + 18, y + 28, COLOR_BG);
  tft.drawLine(x + 11, y + 20, x + 19, y + 28, COLOR_BG);
  tft.drawLine(x + 18, y + 28, x + 32, y + 12, COLOR_BG);
  tft.drawLine(x + 19, y + 28, x + 33, y + 12, COLOR_BG);
}

void drawError(int x, int y, uint16_t color) {
  tft.fillCircle(x + 20, y + 20, 20, color);
  tft.drawLine(x + 10, y + 10, x + 30, y + 30, COLOR_BG);
  tft.drawLine(x + 11, y + 10, x + 31, y + 30, COLOR_BG);
  tft.drawLine(x + 30, y + 10, x + 10, y + 30, COLOR_BG);
  tft.drawLine(x + 31, y + 10, x + 11, y + 30, COLOR_BG);
}

void drawFloatingCloud(int x, int y, int size, uint16_t color) {
  // Draw a simple cloud shape
  int r1 = size;
  int r2 = size * 0.8;
  int r3 = size * 0.6;
  
  tft.fillCircle(x, y, r3, color);
  tft.fillCircle(x + r1, y, r2, color);
  tft.fillCircle(x + r1 * 2, y, r3, color);
  tft.fillRect(x, y, r1 * 2, r3, color);
}

void drawLavaBlob(int x, int y, int size, uint16_t color, int morphOffset) {
  // Draw organic blob shape with DRAMATIC morphing using sine waves
  int r = size;
  float morph1 = sin(morphOffset * 0.08) * 0.6;
  float morph2 = sin(morphOffset * 0.12) * 0.7;
  float morph3 = sin(morphOffset * 0.1) * 0.5;
  float morph4 = sin(morphOffset * 0.15) * 0.8;
  
  // Main body with varying size - bigger changes
  tft.fillCircle(x, y, r * (1 + morph1 * 0.5), color);
  
  // Morphing bumps that change position and size dramatically
  tft.fillCircle(x + r/2 * (1 + morph1 * 1.2), y - r/3 * (1 + morph2 * 1.5), r * 0.7 * (1 + morph2 * 0.8), color);
  tft.fillCircle(x - r/2 * (1 + morph2 * 1.3), y + r/3 * (1 + morph3 * 1.4), r * 0.6 * (1 + morph1 * 0.9), color);
  tft.fillCircle(x + r/3 * (1 + morph3 * 1.5), y + r/2 * (1 + morph1 * 1.2), r * 0.8 * (1 + morph3 * 0.7), color);
  tft.fillCircle(x - r/4 * (1 + morph4 * 1.4), y - r/2 * (1 + morph2 * 1.3), r * 0.5 * (1 + morph4 * 1.0), color);
  tft.fillCircle(x + r/5 * (1 + morph1 * 1.6), y + r/4 * (1 + morph4 * 1.5), r * 0.65 * (1 + morph3 * 0.8), color);
}

void centerText(String text, int y, int size, uint16_t color) {
  tft.setTextSize(size);
  tft.setTextColor(color);
  int w = getTextWidth(text, size);
  tft.setCursor((320 - w) / 2, y);
  tft.print(text);
}

void renderUI() {
  // Only clear full screen if not in wait state (to prevent flashing)
  if (ui != UI_WAIT_NEXT) {
    tft.fillScreen(COLOR_BG);
  }
  
  switch (ui) {
    case UI_WIFI_CONNECTING: {
      drawCard(40, 40, 240, 140, COLOR_CARD_BG);
      drawWifiWaves(160, 70, COLOR_WARNING);
      centerText("Connecting to WiFi", 130, 2, COLOR_TEXT);
      drawSpinner(160, 165, 15, COLOR_PRIMARY);
      break;
    }

    case UI_WIFI_OK: {
      drawCard(40, 40, 240, 140, COLOR_CARD_BG);
      drawWifiWaves(160, 70, COLOR_SUCCESS);
      centerText("WiFi Connected", 130, 2, COLOR_TEXT);
      tft.setTextSize(1);
      tft.setTextColor(COLOR_TEXT_DIM);
      int w = getTextWidth(lastIP, 1);
      tft.setCursor((320 - w) / 2, 155);
      tft.print(lastIP);
      break;
    }

    case UI_TIME_SYNC: {
      drawCard(40, 60, 240, 100, COLOR_CARD_BG);
      centerText("Syncing Time", 95, 2, COLOR_TEXT);
      drawProgressBar(70, 130, 180, 8, 50, COLOR_PRIMARY);
      break;
    }

    case UI_COUNTDOWN: {
      drawCard(60, 50, 200, 140, COLOR_CARD_BG);
      centerText("Get Ready!", 75, 2, COLOR_TEXT);
      String num = String(countdownVal);
      tft.setTextSize(10);
      tft.setTextColor(COLOR_WARNING);
      int w = getTextWidth(num, 10);
      tft.setCursor((320 - w) / 2, 110);
      tft.print(num);
      break;
    }

    case UI_CAPTURE: {
      drawCard(40, 50, 240, 130, COLOR_CARD_BG);
      drawCamera(140, 65, COLOR_PRIMARY);
      centerText("Photo Captured!", 120, 2, COLOR_TEXT);
      tft.setTextSize(1);
      tft.setTextColor(COLOR_TEXT_DIM);
      String sizeText = String(lastSize) + " bytes";
      int w = getTextWidth(sizeText, 1);
      tft.setCursor((320 - w) / 2, 150);
      tft.print(sizeText);
      break;
    }

    case UI_UPLOAD: {
      drawCard(40, 50, 240, 130, COLOR_CARD_BG);
      drawCloud(135, 60, COLOR_PRIMARY);
      centerText("Uploading to S3", 120, 2, COLOR_TEXT);
      drawProgressBar(70, 150, 180, 8, 66, COLOR_PRIMARY);
      break;
    }

    case UI_DONE: {
      drawCard(40, 50, 240, 130, COLOR_CARD_BG);
      drawCheckmark(140, 60, COLOR_SUCCESS);
      centerText("Upload Complete!", 120, 2, COLOR_TEXT);
      if (lastKey.length() > 0) {
        tft.setTextSize(1);
        tft.setTextColor(COLOR_TEXT_DIM);
        String displayKey = lastKey;
        if (displayKey.length() > 30) {
          displayKey = "..." + displayKey.substring(displayKey.length() - 27);
        }
        int w = getTextWidth(displayKey, 1);
        tft.setCursor((320 - w) / 2, 155);
        tft.print(displayKey);
      }
      break;
    }

    case UI_WAIT_NEXT: {
      // Only draw full background on first render
      static bool initialDraw = true;
      if (waitSecondsRemaining == 60 || initialDraw) {
        tft.fillScreen(COLOR_SKY);
        initialDraw = false;
      }
      
      // Calculate blob positions with sine wave motion
      int blob1X = (cloudOffset) % 380 - 40;
      int blob1Y = 120 + sin(cloudOffset * 0.05) * 20;
      
      int blob2X = (cloudOffset + 120) % 400 - 40;
      int blob2Y = 80 + sin((cloudOffset + 50) * 0.04) * 25;
      
      int blob3X = (cloudOffset * 2 + 200) % 420 - 40;
      int blob3Y = 160 + sin((cloudOffset + 100) * 0.06) * 15;
      
      int blob4X = (cloudOffset + 250) % 440 - 40;
      int blob4Y = 50 + sin((cloudOffset + 150) * 0.05) * 30;
      
      int blob5X = (cloudOffset * 3 + 50) % 460 - 40;
      int blob5Y = 200 + sin((cloudOffset + 200) * 0.045) * 20;
      
      int blob6X = (cloudOffset + 320) % 480 - 40;
      int blob6Y = 100 + sin((cloudOffset + 250) * 0.055) * 18;
      
      // Card boundaries - treat as barrier
      int cardLeft = 60;
      int cardRight = 260;
      int cardTop = 50;
      int cardBottom = 170;
      
      // Only redraw blobs occasionally for smooth animation
      if (lastCloudUpdate != cloudOffset) {
        // Erase old blob positions
        int oldBlob1X = (cloudOffset - 2) % 380 - 40;
        int oldBlob1Y = 120 + sin((cloudOffset - 2) * 0.05) * 20;
        
        int oldBlob2X = (cloudOffset - 2 + 120) % 400 - 40;
        int oldBlob2Y = 80 + sin((cloudOffset - 2 + 50) * 0.04) * 25;
        
        int oldBlob3X = ((cloudOffset - 2) * 2 + 200) % 420 - 40;
        int oldBlob3Y = 160 + sin((cloudOffset - 2 + 100) * 0.06) * 15;
        
        int oldBlob4X = (cloudOffset - 2 + 250) % 440 - 40;
        int oldBlob4Y = 50 + sin((cloudOffset - 2 + 150) * 0.05) * 30;
        
        int oldBlob5X = ((cloudOffset - 2) * 3 + 50) % 460 - 40;
        int oldBlob5Y = 200 + sin((cloudOffset - 2 + 200) * 0.045) * 20;
        
        int oldBlob6X = (cloudOffset - 2 + 320) % 480 - 40;
        int oldBlob6Y = 100 + sin((cloudOffset - 2 + 250) * 0.055) * 18;
        
        // Only erase old positions if they weren't touching the barrier
        if (oldBlob1X < cardLeft - 25 || oldBlob1X > cardRight + 25 || 
            oldBlob1Y < cardTop - 25 || oldBlob1Y > cardBottom + 25) {
          drawLavaBlob(oldBlob1X, oldBlob1Y, 14, COLOR_SKY, cloudOffset - 2);
        }
        
        if (oldBlob2X < cardLeft - 30 || oldBlob2X > cardRight + 30 || 
            oldBlob2Y < cardTop - 30 || oldBlob2Y > cardBottom + 30) {
          drawLavaBlob(oldBlob2X, oldBlob2Y, 18, COLOR_SKY, cloudOffset - 2);
        }
        
        if (oldBlob3X < cardLeft - 20 || oldBlob3X > cardRight + 20 || 
            oldBlob3Y < cardTop - 20 || oldBlob3Y > cardBottom + 20) {
          drawLavaBlob(oldBlob3X, oldBlob3Y, 12, COLOR_SKY, cloudOffset - 2);
        }
        
        if (oldBlob4X < cardLeft - 28 || oldBlob4X > cardRight + 28 || 
            oldBlob4Y < cardTop - 28 || oldBlob4Y > cardBottom + 28) {
          drawLavaBlob(oldBlob4X, oldBlob4Y, 16, COLOR_SKY, cloudOffset - 2);
        }
        
        if (oldBlob5X < cardLeft - 26 || oldBlob5X > cardRight + 26 || 
            oldBlob5Y < cardTop - 26 || oldBlob5Y > cardBottom + 26) {
          drawLavaBlob(oldBlob5X, oldBlob5Y, 15, COLOR_SKY, cloudOffset - 2);
        }
        
        if (oldBlob6X < cardLeft - 22 || oldBlob6X > cardRight + 22 || 
            oldBlob6Y < cardTop - 22 || oldBlob6Y > cardBottom + 22) {
          drawLavaBlob(oldBlob6X, oldBlob6Y, 13, COLOR_SKY, cloudOffset - 2);
        }
        
        // Draw new blob positions - stops when touching barrier (deleted)
        // Only draw if NOT touching the card barrier
        if (blob1X < cardLeft - 25 || blob1X > cardRight + 25 || 
            blob1Y < cardTop - 25 || blob1Y > cardBottom + 25) {
          drawLavaBlob(blob1X, blob1Y, 14, COLOR_BLOB1, cloudOffset);
        }
        
        if (blob2X < cardLeft - 30 || blob2X > cardRight + 30 || 
            blob2Y < cardTop - 30 || blob2Y > cardBottom + 30) {
          drawLavaBlob(blob2X, blob2Y, 18, COLOR_BLOB2, cloudOffset);
        }
        
        if (blob3X < cardLeft - 20 || blob3X > cardRight + 20 || 
            blob3Y < cardTop - 20 || blob3Y > cardBottom + 20) {
          drawLavaBlob(blob3X, blob3Y, 12, COLOR_BLOB3, cloudOffset);
        }
        
        if (blob4X < cardLeft - 28 || blob4X > cardRight + 28 || 
            blob4Y < cardTop - 28 || blob4Y > cardBottom + 28) {
          drawLavaBlob(blob4X, blob4Y, 16, COLOR_BLOB4, cloudOffset);
        }
        
        if (blob5X < cardLeft - 26 || blob5X > cardRight + 26 || 
            blob5Y < cardTop - 26 || blob5Y > cardBottom + 26) {
          drawLavaBlob(blob5X, blob5Y, 15, COLOR_BLOB5, cloudOffset);
        }
        
        if (blob6X < cardLeft - 22 || blob6X > cardRight + 22 || 
            blob6Y < cardTop - 22 || blob6Y > cardBottom + 22) {
          drawLavaBlob(blob6X, blob6Y, 13, COLOR_BLOB1, cloudOffset);
        }
        
        lastCloudUpdate = cloudOffset;
      }
      
      // Main content card - only redraw when seconds change
      static int lastDisplayedSeconds = -1;
      if (lastDisplayedSeconds != waitSecondsRemaining || waitSecondsRemaining == 60) {
        drawCard(60, 50, 200, 120, COLOR_CARD_BG);
        centerText("Next Photo In", 70, 2, COLOR_TEXT);
        
        String seconds = String(waitSecondsRemaining);
        tft.setTextSize(12);
        tft.setTextColor(COLOR_PRIMARY);
        int w = getTextWidth(seconds, 12);
        tft.setCursor((320 - w) / 2, 100);
        tft.print(seconds);
        
        tft.setTextSize(1);
        tft.setTextColor(COLOR_TEXT_DIM);
        int w2 = getTextWidth("seconds", 1);
        tft.setCursor((320 - w2) / 2, 155);
        tft.print("seconds");
        
        lastDisplayedSeconds = waitSecondsRemaining;
      }
      
      // Display file info at top - clear area for no blob interference
      static bool infoDrawn = false;
      if (!infoDrawn && lastKey.length() > 0) {
        // Draw small background bars for text readability
        tft.fillRect(0, 0, 320, 11, COLOR_BG);
        tft.fillRect(0, 12, 320, 11, COLOR_BG);
        
        tft.setTextSize(1);
        tft.setTextColor(COLOR_SUCCESS);
        tft.setCursor(3, 2);
        tft.print("Last: ");
        tft.setTextColor(COLOR_TEXT);
        String displayKey = lastKey;
        if (displayKey.length() > 45) {
          displayKey = "..." + displayKey.substring(displayKey.length() - 42);
        }
        tft.print(displayKey);
        
        tft.setCursor(3, 14);
        tft.setTextColor(COLOR_SUCCESS);
        tft.print("Size: ");
        tft.setTextColor(COLOR_TEXT);
        tft.print(lastSize);
        tft.print(" bytes");
        
        infoDrawn = true;
      }
      
      // Reset static flags when leaving this state
      if (waitSecondsRemaining == 0) {
        initialDraw = true;
        infoDrawn = false;
        lastDisplayedSeconds = -1;
      }
      
      break;
    }

    case UI_FAIL: {
      drawCard(40, 50, 240, 130, COLOR_CARD_BG);
      drawError(140, 60, COLOR_DANGER);
      centerText("Upload Failed", 120, 2, COLOR_TEXT);
      centerText("Please try again", 145, 1, COLOR_TEXT_DIM);
      break;
    }

    default: { // UI_BOOT
      drawCard(40, 60, 240, 100, COLOR_CARD_BG);
      centerText("Camera Ready", 95, 2, COLOR_TEXT);
      drawSpinner(160, 135, 12, COLOR_PRIMARY);
      break;
    }
  }
}

void handleEventLine(String line) {
  line.trim();
  if (!line.startsWith("@")) return;

  Serial.println("EVENT: " + line);

  if (line.startsWith("@WIFI:CONNECTING")) { 
    ui = UI_WIFI_CONNECTING; 
    renderUI(); 
    delay(1500);  // Hold for 1.5 seconds
    return; 
  }
  
  if (line.startsWith("@WIFI:OK")) { 
    ui = UI_WIFI_OK; 
    renderUI(); 
    delay(2000);  // Hold for 2 seconds
    return; 
  }

  if (line.startsWith("@WIFI:IP")) {
    lastIP = getValueAfter(line, "ip=");
    ui = UI_WIFI_OK;
    renderUI();
    delay(2000);  // Hold for 2 seconds
    return;
  }

  if (line.startsWith("@TIME:SYNC_START")) { 
    ui = UI_TIME_SYNC; 
    renderUI(); 
    delay(1000);  // Hold for 1 second
    return; 
  }
  
  if (line.startsWith("@TIME:SYNC_OK")) { 
    ui = UI_TIME_SYNC; 
    renderUI(); 
    delay(1500);  // Hold for 1.5 seconds
    return; 
  }

  if (line.startsWith("@COUNT:")) {
    countdownVal = line.substring(String("@COUNT:").length()).toInt();
    ui = UI_COUNTDOWN;
    renderUI();
    return;
  }

  if (line.startsWith("@CAPTURE:START")) { 
    ui = UI_CAPTURE; 
    lastSize = 0; 
    renderUI(); 
    return; 
  }
  
  if (line.startsWith("@CAPTURE:OK")) {
    lastSize = getValueAfter(line, "size=").toInt();
    ui = UI_CAPTURE;
    renderUI();
    delay(1500);  // Hold for 1.5 seconds
    return;
  }
  
  if (line.startsWith("@CAPTURE:FAIL")) { 
    ui = UI_FAIL; 
    renderUI(); 
    return; 
  }

  if (line.startsWith("@S3:KEY")) { lastKey = getValueAfter(line, "key="); return; }

  if (line.startsWith("@S3:UPLOAD_START")) { 
    ui = UI_UPLOAD; 
    renderUI(); 
    return; 
  }
  
  if (line.startsWith("@S3:HTTP")) { 
    ui = UI_UPLOAD; 
    renderUI(); 
    return; 
  }
  
  if (line.startsWith("@S3:UPLOAD_OK")) {
    ui = UI_DONE;
    renderUI();
    delay(3000);  // Hold success screen for 3 seconds
    
    ui = UI_WAIT_NEXT;
    waitStartMillis = millis();
    waitSecondsRemaining = 60;
    renderUI();
    return;
  }

  if (line.startsWith("@S3:UPLOAD_FAIL") || line.startsWith("@S3:CONNECT_FAIL")) {
    ui = UI_FAIL;
    renderUI();
    return;
  }
}

void pollLink() {
  static String buf;
  while (Link.available()) {
    char c = (char)Link.read();
    if (c == '\r') continue;
    if (c == '\n') {
      if (buf.length()) handleEventLine(buf);
      buf = "";
    } else {
      if (buf.length() < 240) buf += c;
    }
  }
}

void updateWaitCountdown() {
  if (ui != UI_WAIT_NEXT) return;
  
  unsigned long elapsed = millis() - waitStartMillis;
  int newSeconds = 60 - (elapsed / 1000);
  
  if (newSeconds < 0) newSeconds = 0;
  
  // Update cloud animation MUCH slower (every ~250ms instead of 100ms)
  static unsigned long lastCloudMove = 0;
  if (millis() - lastCloudMove > 150) {
    cloudOffset = (cloudOffset + 2) % 440;  // Move by 1 pixel instead of 2
    lastCloudMove = millis();
    renderUI();  // Redraw for cloud movement
  }
  
  if (newSeconds != waitSecondsRemaining) {
    waitSecondsRemaining = newSeconds;
    renderUI();  // Redraw for countdown update
  }
  
  if (waitSecondsRemaining == 0) {
    ui = UI_BOOT;
    renderUI();
  }
}

void setup() {
  Serial.begin(115200);
  delay(150);
  Serial.println("WROOM boot");

  tft.init();
  tft.setRotation(1);
  tft.fillScreen(COLOR_BG);

  // Startup animation
  tft.setTextColor(COLOR_SUCCESS);
  tft.setTextSize(3);
  tft.setCursor(60, 100);
  tft.println("LCD Ready");
  delay(700);

  Link.begin(UART_BAUD, SERIAL_8N1, UART_RX_PIN, UART_TX_PIN);
  Serial.println("UART2 started on RX16 TX17");

  ui = UI_BOOT;
  renderUI();
}

void loop() {
  pollLink();
  updateWaitCountdown();
  delay(5);
}