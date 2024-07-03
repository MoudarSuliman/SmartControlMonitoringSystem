#include "ArduinoJson.h"
#include "DHT.h"

#define DHTPIN 7     // DHT sensor pin
#define DHTTYPE DHT11 // DHT 11
#define LIGHT_PIN 12  // LED pin

DHT dht(DHTPIN, DHTTYPE);

unsigned long previousMillis = 0; // Stores last time temperature was updated
const long interval = 900000; // Interval at which to send temperature (15 minutes)

void setup() {
  Serial.begin(19200); 
  pinMode(LIGHT_PIN, OUTPUT); 
  dht.begin();
  Serial.println("DEVICE_ID:mmms");
}

void loop() {
  unsigned long currentMillis = millis();

  // Continuously listen for light status changes
  if (Serial.available() > 0) {
    String lightStatus = Serial.readStringUntil('\n');
    if (lightStatus == "On") {
      digitalWrite(LIGHT_PIN, HIGH); // Turn on the light
    } else {
      digitalWrite(LIGHT_PIN, LOW);  // Turn off the light
    }
  }

  // Send temperature data every 15 minutes
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis; 

    float temperature = dht.readTemperature(); // Reading temperature


    if (!isnan(temperature)) {
      StaticJsonDocument<256> report;
      report["temperature"] = temperature;
      serializeJson(report, Serial);
      Serial.println(); 
    } else {
      Serial.println("Failed to read from DHT sensor!");
    }
  }
}
