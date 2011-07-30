/*

 RC Car Receiver Unit
 version 1.0
 
 The idea: allow to control a car without touching any buttons, 
 just to change an angle of RC unit car will turn left/right/forward/backward.
 
 Hardware:
 0. Arduino Uno (atmega 328)
 2. 4 green LEDs and 4 red LEDs connected to D4,D5,D6,D8 and D9,D10,D11,D12 through a 220 Ohm Resistors
 3. A motor shield
 4. A 433 Mhz receiver unit connected to +5V, GND, 3 
 
 External dependencies: VirtualWire library (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created 28 Jul 2011
 by Andy Karpov <andy.karpov@gmail.com>
*/

#include <VirtualWire.h>
#include <stdio.h>
#include <string.h>
#include "pitches.h"

const int rxPowerPin = A0; // rx power pin
const int rxGndPin = A3; // rx gnd pin
const int rxPin = A1; // rx digital pin
const int txPin = A4; // redefine tx pin
const int pttPin = A5; // redefine ptt pin

const int beepPin = 4; // buzzer pin
const int forwardPin = 2; // forward light pin
const int backwardPin = 3; // backward light pin

const int motorAPin1 = 13; // motor A pin 1
const int motorAPin2 = 12; // motor A pin 2
const int motorASpeedPin = 5; // motor A speed pin (pwm)
const int motorBPin1 = 11; // motor B pin 1
const int motorBPin2 = 8; // motor B pin 2
const int motorBSpeedPin = 6; // motor B speed pin (pwm)

const int timeOut = 1000; // timeout, 1s
const int toneDuration = 200; // tone duration, 0.2s

byte buf[3]; // rx buffer
byte buflen; // rx buffer length

byte btnForward; // forward button state
byte btnBackward; // backward button state
byte btnBeep; // beep button state

byte motorADir; // motor A direction (1 - forward, 0 - backward)
byte motorASpeed; // motor A speed (0..255)

byte motorBDir; // motor B direction (1 - forward, 0 - backward)
byte motorBSpeed; // motor B speed (0..255)

int lastReceived; // last received message timestamp
int lastTone;
boolean beepOn;
 
void setup()
{
  // init defaults
  buflen = 3;
  btnForward = LOW;
  btnBackward = LOW;
  btnBeep = LOW;
  motorADir = 1;
  motorBDir = 1;
  motorASpeed = 0;
  motorBSpeed = 0;
  lastReceived = 0;
  lastTone = 0;
  beepOn = false;
 
   // debug to serial
  // Serial.begin(9600);
  // Serial.println("starting");
 
  pinMode(rxPowerPin, OUTPUT);
  pinMode(rxGndPin, OUTPUT);
  pinMode(rxPin, INPUT);

  digitalWrite(rxPowerPin, HIGH);
  digitalWrite(rxGndPin, LOW);

  pinMode(motorAPin1, OUTPUT);
  pinMode(motorAPin2, OUTPUT);
  pinMode(motorASpeedPin, OUTPUT);
  pinMode(motorBPin1, OUTPUT);
  pinMode(motorBPin2, OUTPUT);
  pinMode(motorBSpeedPin, OUTPUT);
   
  // initiate RX unit
  vw_set_rx_pin(rxPin);
  vw_set_tx_pin(txPin);
  vw_set_ptt_pin(pttPin);
  vw_setup(2000);
  vw_rx_start();
}

void loop()
{
  if (vw_get_message(buf, &buflen)) {
     
     lastReceived = millis();
    
     // get received values from RX module and decode them
     motorASpeed = buf[0];
     motorBSpeed = buf[1];
     motorADir =  (buf[2] & B00000001) ? 1 : 0;
     motorBDir =  (buf[2] & B00000010) ? 1 : 0;
     btnForward = (buf[2] & B00000100) ? HIGH : LOW;
     btnBackward= (buf[2] & B00001000) ? HIGH : LOW;
     btnBeep    = (buf[2] & B00010000) ? HIGH : LOW;
     
     // dump debug to serial
     /* Serial.print("A:");
     Serial.print(motorASpeed, HEX);
     Serial.print("|");
     Serial.print(motorADir, HEX);
     
     Serial.print(" B:");
     Serial.print(motorBSpeed, HEX);
     Serial.print("|");
     Serial.print(motorBDir, HEX);
     
     Serial.print(" FW:");
     Serial.print(btnForward, HEX);
     Serial.print(" BW:");
     Serial.print(btnBackward, HEX);
     Serial.print(" BE:");
     Serial.print(btnBeep, HEX);
     Serial.println();
     */
  }
  
   // reset values on rx timeout
   if (millis() - lastReceived > timeOut) {
     motorADir = 1;
     motorBDir = 1;
     motorASpeed = 0;
     motorBSpeed = 0;
     btnForward = 0;
     btnBackward = 0;
     btnBeep = 0;
   }
  
   // set speed and directions
   analogWrite(motorASpeedPin, motorASpeed);
   analogWrite(motorBSpeedPin, motorBSpeed);
   
   digitalWrite(motorAPin1, ((motorADir == 1) ? HIGH : LOW));
   digitalWrite(motorAPin2, ((motorADir == 1) ? LOW : HIGH));
   
   digitalWrite(motorBPin1, ((motorBDir == 1) ? HIGH : LOW));
   digitalWrite(motorBPin2, ((motorBDir == 1) ? LOW : HIGH)); 
   
   digitalWrite(forwardPin, ((btnForward == 1) ? HIGH : LOW));
   digitalWrite(backwardPin, ((btnBackward == 1) ? HIGH : LOW));
   
   if (millis() - lastTone > toneDuration) {
      lastTone = millis();
      beepOn = !beepOn;
   }
   
   if (beepOn & (millis() - lastReceived > timeOut)) {
      tone(beepPin, NOTE_C4);
   } else {
     noTone(beepPin); 
   }
}
