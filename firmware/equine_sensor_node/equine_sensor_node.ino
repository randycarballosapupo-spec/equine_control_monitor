#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <WiFi.h>
#include <HTTPClient.h>

HardwareSerial gsm(1);

const char* WIFI_SSID = "REPLACE_WITH_WIFI_NAME";
const char* WIFI_PASSWORD = "REPLACE_WITH_WIFI_PASSWORD";
const char* CLOUD_ENDPOINT = "";
const char* DEVICE_ID = "esp32s3-node-01";
const char* HORSE_ID = "horse-01";
const char* ADMIN_PHONE = "+REPLACE_ADMIN_PHONE";
const int GSM_RX_PIN = 16;
const int GSM_TX_PIN = 17;
const float AMMONIA_WARNING = 10.0f;
const float AMMONIA_CRITICAL = 25.0f;
const float AIR_QUALITY_WARNING = 50.0f;

static const char* SERVICE_UUID = "7f8f0001-5d4c-4d9d-9c10-ec0000000001";
static const char* READING_UUID = "7f8f0002-5d4c-4d9d-9c10-ec0000000002";

BLECharacteristic* readingCharacteristic = nullptr;
bool bleConnected = false;
unsigned long lastReadingAt = 0;
unsigned long lastEnvironmentalSmsAt = 0;
float latestAmmonia = 0.0f;
float latestAirQuality = 100.0f;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    bleConnected = true;
  }

  void onDisconnect(BLEServer* server) override {
    bleConnected = false;
    server->getAdvertising()->start();
  }
};

String createReadingJson() {
  const float temperature = 21.0f + (float)(millis() % 40) / 10.0f;
  const float humidity = 55.0f + (float)(millis() % 80) / 10.0f;
  const float ammonia = 1.0f + (float)(millis() % 30) / 10.0f;
  const float airQuality = 82.0f + (float)(millis() % 150) / 10.0f;
  latestAmmonia = ammonia;
  latestAirQuality = airQuality;

  String payload = "{";
  payload += "\"moduleType\":\"central\",";
  payload += "\"sourceModuleId\":\"submodule-demo-01\",";
  payload += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
  payload += "\"horseId\":\"" + String(HORSE_ID) + "\",";
  payload += "\"timestamp\":\"" + String((unsigned long long)time(nullptr)) + "\",";
  payload += "\"temperature\":" + String(temperature, 1) + ",";
  payload += "\"humidity\":" + String(humidity, 1) + ",";
  payload += "\"ammonia\":" + String(ammonia, 1) + ",";
  payload += "\"airQuality\":" + String(airQuality, 1) + ",";
  payload += "\"dust\":0.0,";
  payload += "\"pollen\":0.0";
  payload += "}";
  return payload;
}

void sendAdminSms(const String& message) {
  if (String(ADMIN_PHONE).startsWith("+REPLACE")) return;
  gsm.println("AT+CMGF=1");
  delay(300);
  gsm.print("AT+CMGS=\"");
  gsm.print(ADMIN_PHONE);
  gsm.println("\"");
  delay(300);
  gsm.print(message);
  gsm.write(26);
  delay(1000);
}

void evaluateEnvironmentalAlerts(float ammonia, float airQuality) {
  if (millis() - lastEnvironmentalSmsAt < 600000UL) return;
  String message;
  if (ammonia >= AMMONIA_CRITICAL) {
    message = "ALERTA AMBIENTAL CRITICA caballo=" + String(HORSE_ID) + " amoniaco=" + String(ammonia, 1) + "ppm";
  } else if (ammonia >= AMMONIA_WARNING) {
    message = "ALERTA AMBIENTAL caballo=" + String(HORSE_ID) + " amoniaco=" + String(ammonia, 1) + "ppm";
  }
  if (airQuality <= AIR_QUALITY_WARNING) {
    message = "ALERTA AMBIENTAL caballo=" + String(HORSE_ID) + " calidad_aire=" + String(airQuality, 1);
  }
  if (message.isEmpty()) return;
  sendAdminSms(message);
  lastEnvironmentalSmsAt = millis();
}

void sendToCloud(const String& payload) {
  if (String(CLOUD_ENDPOINT).isEmpty() || WiFi.status() != WL_CONNECTED) return;
  HTTPClient http;
  http.begin(CLOUD_ENDPOINT);
  http.addHeader("Content-Type", "application/json");
  http.POST(payload);
  http.end();
}

void setupBle() {
  BLEDevice::init(DEVICE_ID);
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService* service = server->createService(SERVICE_UUID);
  readingCharacteristic = service->createCharacteristic(
    READING_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  readingCharacteristic->addDescriptor(new BLE2902());
  service->start();
  server->getAdvertising()->addServiceUUID(SERVICE_UUID);
  server->getAdvertising()->start();
}

void setupWifi() {
  if (String(WIFI_SSID).startsWith("REPLACE_")) return;
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long startedAt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startedAt < 15000) {
    delay(250);
  }
}

void setupGsm() {
  gsm.begin(115200, SERIAL_8N1, GSM_RX_PIN, GSM_TX_PIN);
  delay(500);
  gsm.println("AT");
}

void setup() {
  Serial.begin(115200);
  delay(500);
  setupBle();
  setupWifi();
  setupGsm();
}

void loop() {
  if (millis() - lastReadingAt < 5000) return;
  lastReadingAt = millis();

  const String payload = createReadingJson();
  Serial.println(payload);
  evaluateEnvironmentalAlerts(latestAmmonia, latestAirQuality);

  if (bleConnected && readingCharacteristic != nullptr) {
    readingCharacteristic->setValue(payload.c_str());
    readingCharacteristic->notify();
  }

  sendToCloud(payload);
}
