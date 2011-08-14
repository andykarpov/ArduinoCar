/*

 ArduinoCar Test Unit
 version 1.1
 
 Test unit to display a received values from transmitter 
 on the LCD 16x2 screen 
 
 Hardware:
 1. Arduino Uno (atmega 328)
 2. A 16x2 LCD
 3. A 433 Mhz receiver unit connected to +5V, GND, D3 
 
 External dependencies: VirtualWire library 
 (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created  28 Jul 2011
 modified 14 Aug 2011
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

byte buf[9]; // rx buffer
byte buflen; // rx buffer length

byte btnForward; // forward button state
byte btnBackward; // backward button state
byte btnBeep; // beep button state

int xval; // accelerometer x value
int yval; // accelerometer y value

// SETUP routine
void setup()
{
  // init defaults
  buflen = 9;
  btnForward = LOW;
  btnBackward = LOW;
  btnBeep = LOW;
 
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
     lcd.print("X: ");
     lcd.print(xval, DEC);
     
     lcd.print(" Y: ");
     lcd.print(yval, DEC);
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

    char val[4];
    
    // reading x value
    val[0] = buf[0];
    val[1] = buf[1];
    val[2] = buf[2];
    val[3] = buf[3];
    xval = atoi(val);
    
    // reading x value
    val[0] = buf[4];
    val[1] = buf[5];
    val[2] = buf[6];
    val[3] = buf[7];
    yval = atoi(val);
    
     // get button values and decode them
     btnForward = (buf[8] & B00000001) ? HIGH : LOW;
     btnBackward= (buf[8] & B00000010) ? HIGH : LOW;
     btnBeep    = (buf[8] & B00000100) ? HIGH : LOW;
   }
}
