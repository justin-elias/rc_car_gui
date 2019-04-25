/*
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleWrite.cpp
    Ported to Arduino ESP32 by Evandro Copercini
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <ESP32Servo.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

// UUID for advertisement
#define SERVICE_UUID        "ae563286-b114-49ae-aab3-3cc37bbfe46a"

// UUIDs for control characteristics
#define RIGHT_CHARACTERISTIC_UUID "fc131b73-9e78-4ee6-a837-03edd24b66f9"
#define LEFT_CHARACTERISTIC_UUID "e3956242-861b-4545-a006-6d3cfdc7bc2b"
#define GEAR_CHARACTERISTIC_UUID "2a741394-d7f4-45de-88d2-e888f50d763e"

// Servo variables
Servo rightServo;
Servo leftServo;

// Set initial gear to 1
int gear = 1;

// Speed multiplier. Multiplied by gear to set Servo output. 
int speedo = 100;


// Take action when Right CHaracteristic changes
class RightCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic_RIGHT) {
      std::string value = pCharacteristic_RIGHT->getValue();

      // Min gear was too fast, so if gear is 1, decrease speed by half
      if (gear == 1) {
          speedo = 50;
        }
        else {
          speedo = 100;
        }
  
      if (value.length() > 0) {
        Serial.println("*********");
        Serial.print("value length: ");
        Serial.println(value.length());
        Serial.print("New value: ");
        for (int i = 0; i < value.length(); i++)
          Serial.print(value[i]);
        Serial.println();

        // Set Forward speed
        if (value == "1") {
          int setting = 1500 - (speedo*gear);
          Serial.println("Right Forward: ");
          Serial.print(setting);
          rightServo.writeMicroseconds(setting);

        }

        // Set Reverse Speed
        if (value == "2") {
          int setting = 1500 + (speedo*gear);
          Serial.println(" Right Reverse: ");
          Serial.print(setting);
          rightServo.writeMicroseconds(setting);
        }

        // Stop Servo
        if (value == "0") {
          Serial.println("Right Stopped");
          rightServo.writeMicroseconds(1500);
        }
        Serial.println("*********");
      }
    }
};

// Take action when Right CHaracteristic changes
class LeftCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic_LEFT) {
      std::string value = pCharacteristic_LEFT->getValue();

      // Min gear was too fast, so if gear is 1, decrease speed by half
      if (gear == 1) {
          speedo = 50;
        }
        else {
          speedo = 100;
        }

      if (value.length() > 0) {
        Serial.println("*********");
        Serial.print("value length: ");
        Serial.println(value.length());
        Serial.print("New value: ");
        for (int i = 0; i < value.length(); i++)
          Serial.print(value[i]);
        Serial.println();

        // Set Forward speed
        if (value == "1") {
          int setting = 1500 + (speedo*gear);
          Serial.println("Left Forward: ");
          Serial.print(setting);
          leftServo.writeMicroseconds(setting);

        }

        // Set Reverse speed
        if (value == "2") {
          int setting = 1500 - (speedo*gear);
          Serial.println(" Left Reverse: ");
          Serial.print(setting);
          leftServo.writeMicroseconds(setting);
        }

        // Stop servo
        if (value == "0") {
          Serial.println("Left Stopped");
          leftServo.writeMicroseconds(1500);
        }
        Serial.println("*********");
      }
    }
};

// Take action when Gear Charactersitic is changed
class GearCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic_GEAR) {
      std::string value = pCharacteristic_GEAR->getValue();
      int i = value.length()-1;
      Serial.print("+++ ");
      Serial.println(value[i]);
      if (value.length() > 0) {
        Serial.println("*********");
        Serial.print("value length: ");
        Serial.println(value.length());
        Serial.print("New value: ");
        for (int i = 0; i < value.length(); i++)
          Serial.print(value[i]);
        Serial.println();
        
        gear = atoi( value.c_str());
        Serial.print("Gear set to: ");
        Serial.println(gear);
      }
    }
};

void setup() {

  // Attach servo to pins
  rightServo.attach(4);
  leftServo.attach(12);

  Serial.begin(115200);

  // Set servos to stop
  rightServo.writeMicroseconds(1500);
  leftServo.writeMicroseconds(1500);

  // Set bluetooth characteristics 
  BLEDevice::init("Team F6");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  BLECharacteristic *pCharacteristic_RIGHT = pService->createCharacteristic(
        RIGHT_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE
      );
  BLECharacteristic *pCharacteristic_LEFT = pService->createCharacteristic(
        LEFT_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE
      );
   BLECharacteristic *pCharacteristic_GEAR = pService->createCharacteristic(
        GEAR_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE
      );

  // What should we do when a characteristic is written to
  pCharacteristic_RIGHT->setCallbacks(new RightCallbacks());
  pCharacteristic_RIGHT->setValue("Right ServoControl");
  
  pCharacteristic_LEFT->setCallbacks(new LeftCallbacks());
  pCharacteristic_LEFT->setValue("Left ServoControl");
  
  pCharacteristic_GEAR->setCallbacks(new GearCallbacks());
  pCharacteristic_GEAR->setValue("GEAR SETTING");
  
  // Begin bluetooth advertisement
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
}

void loop() {

  delay(2000);


}
