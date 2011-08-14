/*

 ArduinoCar Receiver Unit
 version 1.1
 
 Receive a 9 byte length message from transmitter and control motors, 
 forward and backward leds and beep some tones via buzzer.
 
 If there is no transmission detected or timeout - system will blink all leds 
 and beep every 100ms.
 
 Otherwise a car will be moved depends on received x and y values 
 from accelerometer and forward / backward button states.
 
 Message data packed into the 9 bytes array:
 byte 0..3 - X value
 byte 4..7 - Y value 
 byte 8 - mixed data, each bit is a state, such as:
 - bit 0 - forward LED state ( 1 - HIGH, 0 - LOW)
 - bit 1 - backward LED state ( 1 - HIGH, 0 - LOW)
 - bit 2 - buzzer state ( 1 - play a buzz, 0 - silence) 
 
 Hardware:
 0. Arduino Uno (atmega 328)
 2. 2 blue LEDs connected to D2 and GND via 270 Ohm resistor.
 3. 2 red LEDs connected to D7 and GND via 270 Ohm resistor. 
 4. A motor shield (L298N based, modified to use PWM pins 5 and 6 
    instead of 10 and 11 to avoid intersection with VirtualWire TIMER1 interrupt)
 5. A 433 Mhz receiver unit connected to +5V (or A0), GND (or A3), A1 (DATA) 
 
 External dependencies: VirtualWire library 
 (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created  28 Jul 2011
 modified 14 Aug 2011
 by Andy Karpov <andy.karpov@gmail.com>
*/

#include <VirtualWire.h>
#include <stdio.h>
#include <string.h>
#include "pitches.h"

const int rxPowerPin = A0; // rx power pin
const int rxGndPin = A3; // rx gnd pin
const int rxPin = A1; // rx digital pin
const int txPin = A4; // redefined tx pin
const int pttPin = A5; // redefined ptt pin
const int rxSpeed = 2000; // radio unit speed

const int beepPin = 4; // buzzer pin
const int forwardPin = 2; // forward light pin
const int backwardPin = 7; // backward light pin

const int motorAPin1 = 13; // motor A pin 1
const int motorAPin2 = 12; // motor A pin 2
const int motorASpeedPin = 5; // motor A speed pin (pwm)
const int motorBPin1 = 11; // motor B pin 1
const int motorBPin2 = 8; // motor B pin 2
const int motorBSpeedPin = 6; // motor B speed pin (pwm)

const int timeOut = 500; // rx timeout
const int numRetries = 2; // rx retries
const int toneDuration = 50; // tone duration on rx timeout

byte buf[9]; // rx buffer
byte buflen = 9; // rx buffer length

int xval = 0; // x value
int yval = 0; // y value
byte btnForward = LOW; // forward button state
byte btnBackward = LOW; // backward button state
byte btnBeep = LOW; // beep button state

int motorADir = 1; // motor A direction (1 - forward, 0 - backward)
int motorASpeed = 0; // motor A speed (0..255)

int motorBDir = 1; // motor B direction (1 - forward, 0 - backward)
int motorBSpeed = 0; // motor B speed (0..255)

unsigned long lastReceived = 0; // last received message timestamp
unsigned long lastTone = 0; // last tone timestamp
boolean beepOn = false; // beeper on flag
int noSignal = 1; // no signal flag
 
// SETUP routine
void setup()
{
  // set pin modes
  pinMode(rxPowerPin, OUTPUT);
  pinMode(rxGndPin, OUTPUT);
  pinMode(rxPin, INPUT);

  pinMode(motorAPin1, OUTPUT);
  pinMode(motorAPin2, OUTPUT);
  pinMode(motorASpeedPin, OUTPUT);
  pinMode(motorBPin1, OUTPUT);
  pinMode(motorBPin2, OUTPUT);
  pinMode(motorBSpeedPin, OUTPUT);
  
  pinMode(forwardPin, OUTPUT);
  pinMode(backwardPin, OUTPUT);

  // enable radio unit power
  digitalWrite(rxPowerPin, HIGH);
  digitalWrite(rxGndPin, LOW);
   
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
  // get a current timestamp
  unsigned long curTime = millis();
  
  //waiting for transmission until timeout
  if (vw_wait_rx_max(timeOut)) {
  
    // virtualwire message processing
    if (vw_get_message(buf, &buflen)) {
       
       // get received values from RX module and decode them
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
       btnForward = (buf[8] & B00000100) ? HIGH : LOW;
       btnBackward= (buf[8] & B00001000) ? HIGH : LOW;
       btnBeep    = (buf[8] & B00010000) ? HIGH : LOW;
       
       // calc motor direction
       if (btnForward == HIGH) {
          motorADir = 1;
          motorBDir = 1;
       }
       if (btnBackward == HIGH) {
          motorADir = 0;
          motorBDir = 0;
       }
       
       // calculate motor speed
       if (btnForward == HIGH || btnBackward == HIGH) {
          motorASpeed = 255;
          motorBSpeed = 255;
          
          if (yval >= 532) {
              motorADir = (motorBDir == 1) ? 0 : 1;
           } else if (yval <=440) {
              motorBDir = (motorADir == 1) ? 0 : 1;
           }
       } else {
          motorASpeed = 0;
          motorBSpeed = 0;
       }
    }
    noSignal = 0;
  } else {
     noSignal++;
     if (noSignal > numRetries) {
       motorADir = 1;
       motorBDir = 1;
       motorASpeed = 0;
       motorBSpeed = 0;
       btnForward = 0;
       btnBackward = 0;
       btnBeep = 0;
     }
  }
  
   // set motors direction   
   digitalWrite(motorAPin1, ((motorADir == 1) ? HIGH : LOW));
   digitalWrite(motorAPin2, ((motorADir == 1) ? LOW : HIGH));
   digitalWrite(motorBPin1, ((motorBDir == 1) ? HIGH : LOW));
   digitalWrite(motorBPin2, ((motorBDir == 1) ? LOW : HIGH)); 

   // set motors speed
   analogWrite(motorASpeedPin, motorASpeed);
   analogWrite(motorBSpeedPin, motorBSpeed);
   
   // set LEDs state
   digitalWrite(forwardPin, ((btnForward == 1) ? HIGH : LOW));
   digitalWrite(backwardPin, ((btnBackward == 1) ? HIGH : LOW));
   
   // beep cycle on rx timeout
   if (curTime - lastTone > toneDuration) {
      lastTone = curTime;
      beepOn = !beepOn;
   }
   
   if (beepOn && noSignal) {
      tone(beepPin, NOTE_E7);
      digitalWrite(forwardPin, HIGH);
      digitalWrite(backwardPin, HIGH);
   } else if (!beepOn && noSignal) {
       noTone(beepPin); 
         digitalWrite(forwardPin, LOW);
         digitalWrite(backwardPin, LOW);  
   }
 
   // normal beep, when received btnBeep state   
   if (btnBeep && !noSignal) {
     tone(beepPin, NOTE_E5);
   } else if (!btnBeep && !noSignal) {
     noTone(beepPin);
   }  
}
