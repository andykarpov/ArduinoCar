/*

 RC Car Test Unit
 version 1.0
 
 The idea: allow to control a car without touching any buttons, 
 just to change an angle of RC unit car will turn left/right/forward/backward.
 
 Hardware:
 1. Arduino Uno (atmega 328)
 2. A 16x1 LCD
 3. A 433 Mhz receiver unit connected to +5V, GND, 3 
 
 External dependencies: VirtualWire library (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created 28 Jul 2011
 by Andy Karpov <andy.karpov@gmail.com>
*/

#include <VirtualWire.h>
#include <stdio.h>
#include <string.h>
#include <LiquidCrystal.h>

LiquidCrystal lcd(8, 7, 6, 5, 4, 3, 2);

const int rxPowerPin = A0; // rx power pin
const int rxGndPin = A3; // rx gnd pin
const int rxPin = A1; // rx digital pin

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
 
  pinMode(rxPowerPin, OUTPUT);
  pinMode(rxGndPin, OUTPUT);
  pinMode(rxPin, INPUT);

  digitalWrite(rxPowerPin, HIGH);
  digitalWrite(rxGndPin, LOW);
  
  lcd.begin(16, 2);
  delay(1000);
  lcd.print("starting");
  
  digitalWrite(13, HIGH);
   
  // initiate RX unit
  vw_setup(2000);
  vw_set_rx_pin(rxPin);
  vw_rx_start(); 
}

void loop()
{
     lcd.setCursor(0, 0);
     
     // dump debug to serial
     lcd.print("A: ");
     lcd.print(motorASpeed, HEX);
     lcd.print("|");
     lcd.print(motorADir, HEX);
     
     lcd.print(" B: ");
     lcd.print(motorBSpeed, HEX);
     lcd.print("|");
     lcd.print(motorBDir, HEX);
     lcd.print("        ");
     
     lcd.setCursor(0, 1);
     
     lcd.print("FW:");
     lcd.print(btnForward, HEX);
     lcd.print(" BW:");
     lcd.print(btnBackward, HEX);
     lcd.print(" BE:");
     lcd.print(btnBeep, HEX);
     lcd.print("        ");

  if (vw_get_message(buf, &buflen)) {
     
    digitalWrite(13, HIGH);
    
     // get received values from RX module and decode them
     motorASpeed = buf[0];
     motorBSpeed = buf[1];
     motorADir =  (buf[2] & B00000001) ? 1 : 0;
     motorBDir =  (buf[2] & B00000010) ? 1 : 0;
     btnForward = (buf[2] & B00000100) ? HIGH : LOW;
     btnBackward= (buf[2] & B00001000) ? HIGH : LOW;
     btnBeep    = (buf[2] & B00010000) ? HIGH : LOW;
   }
}
