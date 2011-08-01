/*

 ArduinoCar Test Unit
 version 1.0
 
 Test unit to display a received values on the LCD 16x2 screen 
 
 Hardware:
 1. Arduino Uno (atmega 328)
 2. A 16x2 LCD
 3. A 433 Mhz receiver unit connected to +5V, GND, D3 
 
 External dependencies: VirtualWire library 
 (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created  28 Jul 2011
 modified 01 Aug 2011
 by Andy Karpov <andy.karpov@gmail.com>
*/

#include <VirtualWire.h>
#include <stdio.h>
#include <string.h>
#include <LiquidCrystal.h>

// init LCD library, module connected to 12,11,10,5,4,3,2 digital pins
// backlight is connected to pin 13 and GND
LiquidCrystal lcd(12, 11, 10, 5, 4, 3, 2);

const int rxPowerPin = A0; // rx power pin
const int rxGndPin = A3; // rx gnd pin
const int rxPin = A1; // rx digital pin
const int txPin = 1; // redefine tx pin
const int pttPin = 0; // redefine ptt pin
const int rxSpeed = 2000; // rx speed

byte buf[3]; // rx buffer
byte buflen; // rx buffer length

byte btnForward; // forward button state
byte btnBackward; // backward button state
byte btnBeep; // beep button state

byte motorADir; // motor A direction (1 - forward, 0 - backward)
byte motorASpeed; // motor A speed (0..255)

byte motorBDir; // motor B direction (1 - forward, 0 - backward)
byte motorBSpeed; // motor B speed (0..255)

// SETUP routine
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
 
  // set pin modes
  pinMode(rxPowerPin, OUTPUT);
  pinMode(rxGndPin, OUTPUT);
  pinMode(rxPin, INPUT);

  // power up receiver
  digitalWrite(rxPowerPin, HIGH);
  digitalWrite(rxGndPin, LOW);
  
  // init LCD
  lcd.begin(16, 2);
  delay(1000);
  lcd.print("starting");
  
  // init LCD highlight
  digitalWrite(13, HIGH);
   
  // initiate RX unit
  vw_set_rx_pin(rxPin);
  vw_set_tx_pin(txPin);
  vw_set_ptt_pin(pttPin);
  vw_setup(rxSpeed);
  vw_rx_start();
}

// MAIN LOOP routine
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
