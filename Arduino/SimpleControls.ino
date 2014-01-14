    /*

Copyright (c) 2012, 2013 RedBearLab

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

//"services.h/spi.h/boards.h" is needed in every new project
#include <SPI.h>
#include <boards.h>
#include <ble_shield.h>
#include <services.h>
#include <Servo.h> 
 
#define DIGITAL_OUT_PIN    4
#define DIGITAL_IN_PIN     5
#define PWM_PIN            6
#define SERVO_PIN          7
#define ANALOG_IN_PIN      A5

typedef enum PinTypeKey {
    kPinTypeDigital = 1,
    kPinTypePWM = 2,
    kPintypeServo = 3,
    kPinTypeAnalogReading = 160,
    kPinTypeDigitalRead = 10,
    kPinTypeAnalogValuePin = 11
}PinTypeKey;

typedef enum OnOffValueKey{
    kOnValue = 1, 
    kOffValue = 0
}OnOffValueKey;


#define kDigitalOn 1
#define kDigitalOff 0

Servo myservo;

void setup()
{
  // Default pins set to 9 and 8 for REQN and RDYN
  // Set your REQN and RDYN here before ble_begin() if you need
  //ble_set_pins(3, 2);
  
  // Init. and start BLE library.
  ble_begin();
  
  // Enable serial debug
  Serial.begin(57600);
  
  pinMode(DIGITAL_OUT_PIN, OUTPUT);
  pinMode(DIGITAL_IN_PIN, INPUT);
  
  // Default to internally pull high, change it if you need
  digitalWrite(DIGITAL_IN_PIN, HIGH);
  //digitalWrite(DIGITAL_IN_PIN, LOW);
  
  myservo.attach(SERVO_PIN);
}

void loop()
{
  static boolean analog_enabled = false;
  static byte old_state = LOW;
  // If data is ready
  while(ble_available())
  {
    // read out command and data
    int data0 = ble_read();
    int data1 = ble_read();
    
    Serial.println("BLE Available");
    
    if (data0 == kPinTypeDigital)  // Command is to control digital out pin
    {
      Serial.print("Its a digital command");
      if (data1 == kOnValue){
      Serial.print("Just before digital write");
        digitalWrite(DIGITAL_OUT_PIN, HIGH);
      }else{
        digitalWrite(DIGITAL_OUT_PIN, LOW);
      }
    }
    else if (data0 == kPinTypeAnalogReading) // Command is to enable analog in reading
    {
      if (data1 == kOnValue)
        analog_enabled = true;
      else
        analog_enabled = false;
    }
    else if (data0 == kPinTypePWM) // Command is to control PWM pin
    {
      analogWrite(PWM_PIN, data1);
    }
    else if (data0 == kPintypeServo)  // Command is to control Servo pin
    {
      myservo.write(data1);
    }
    else if (data0 == 0x04)
    {
      analog_enabled = false;
      myservo.write(0);
      analogWrite(PWM_PIN, 0);
      digitalWrite(DIGITAL_OUT_PIN, LOW);
    }
  }
  
  if (analog_enabled)  // if analog reading enabled
  {
    // Read and send out
    uint16_t value = analogRead(ANALOG_IN_PIN); 
    ble_write(0x0B);
    ble_write(value >> 8);
    ble_write(value);
  }
  
  // If digital in changes, report the state
  if (digitalRead(DIGITAL_IN_PIN) != old_state)
  {
    old_state = digitalRead(DIGITAL_IN_PIN);
    
    if (digitalRead(DIGITAL_IN_PIN) == HIGH)
    {
      ble_write(0x0A);
      ble_write(0x01);
      ble_write(0x00);    
    }
    else
    {
      ble_write(0x0A);
      ble_write(0x00);
      ble_write(0x00);
    }
  }
  
  if (!ble_connected())
  {
    analog_enabled = false;
    digitalWrite(DIGITAL_OUT_PIN, LOW);
  }
  
  // Allow BLE Shield to send/receive data
  ble_do_events();  
}



