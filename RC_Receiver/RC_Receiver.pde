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

const int rxPowerPin = A0; // rx power pin
const int rxGndPin = A3; // rx gnd pin
const int rxPin = A1; // rx digital pin
const int txPin = A4; // redefine tx pin
const int pttPin = A5; // redefine ptt pin

/*const int ledCount = 4; // led count per motor
const int ledPinsA[] = {9,10,11,12}; // leds for motor A
const int ledPinsB[] = {4,5,6,8}; // leds for motor B

const int beepPin = 2; // buzzer pin
const int forwardLightPin = 1; // forward light pin
const int backwardLightPin = 13; // backward light pin
*/

const int motorAPin1 = 13;
const int motorAPin2 = 12;
const int motorASpeedPin = 10;
const int motorBPin1 = 11;
const int motorBPin2 = 8;
const int motorBSpeedPin = 9;


byte buf[3]; // rx buffer
byte buflen; // rx buffer length

byte btnForward; // forward button state
byte btnBackward; // backward button state
byte btnBeep; // beep button state

byte motorADir; // motor A direction (1 - forward, 0 - backward)
byte motorASpeed; // motor A speed (0..255)

byte motorBDir; // motor B direction (1 - forward, 0 - backward)
byte motorBSpeed; // motor B speed (0..255)
 
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
 
   // debug to serial
  Serial.begin(9600);
  Serial.println("starting");
 
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
     
     // get received values from RX module and decode them
     motorASpeed = buf[0];
     motorBSpeed = buf[1];
     motorADir =  (buf[2] & B00000001) ? 1 : 0;
     motorBDir =  (buf[2] & B00000010) ? 1 : 0;
     btnForward = (buf[2] & B00000100) ? HIGH : LOW;
     btnBackward= (buf[2] & B00001000) ? HIGH : LOW;
     btnBeep    = (buf[2] & B00010000) ? HIGH : LOW;
     
     // dump debug to serial
     Serial.print("A:");
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
   }
   
     // set speed and directions
     analogWrite(motorASpeedPin, motorASpeed);
     analogWrite(motorBSpeedPin, motorBSpeed);
     digitalWrite(motorAPin1, (motorADir == 1) ? LOW : HIGH);
     digitalWrite(motorAPin2, (motorADir == 1) ? HIGH : LOW);
     digitalWrite(motorBPin1, (motorBDir == 1) ? HIGH : LOW);
     digitalWrite(motorBPin2, (motorBDir == 1) ? LOW : HIGH);
}
