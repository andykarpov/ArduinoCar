/*

 ArduinoCar Receiver Unit
 version 1.2
 
 Receive a 4 byte length message from transmitter and control motors, 
 forward and backward leds and beep some tones via buzzer.
 
 If there is no transmission detected or timeout - system will blink all leds 
 and beep every 100ms.
 
 Otherwise a car will be moved depends on received x and y values 
 from accelerometer and forward / backward button states.
 
 Message data packed into the 4 bytes array:
 byte 0 - X value
 byte 1 - Y value
 byte 2 - R value  
 byte 3 - mixed data, each bit is a state, such as:
 - bit 0 - forward LED state ( 1 - HIGH, 0 - LOW)
 - bit 1 - backward LED state ( 1 - HIGH, 0 - LOW)
 - bit 2 - buzzer state ( 1 - play a buzz, 0 - silence) 
 
 Hardware:
 0. ATmega328P-PU microcontroller (DIP package)
 2. 2 blue 5mm LEDs connected to D2 and GND via 270 Ohm resistor.
 3. 2 red 5mm LEDs connected to D7 and GND via 270 Ohm resistor. 
 4. L293D motor driver (DIP package)
 5. A 433 Mhz receiver unit connected to +5V, GND and A1 (DATA) 
 6. A small servo connected to +5V, GND and D3
 7. 4 AA 1.5v batteries
 8. buzzer
 9. 16.000 MHz oscillator
 10. 2x 10pf capacitors
 11. 6x 0.1uF capacitors
 12. 2x 1000uF 6.3V capacitors
 13. Soldering proto board
 14. 4 wheel platform with 2x 5V motors
 15. antenna
 16. power switch (to power on / off)
 17. a bit of hook up wires
 18. 1x 10k resistor
 19. small switch (for reset button)
 20. battery holder for 4 AA batteries
 
 External dependencies: VirtualWire library 
 (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 and ServoTimer2 library
 (http://www.arduino.cc/playground/uploads/Main/ServoTimer2.zip)
 
 created  28 Jul 2011
 modified 04 Nov 2011
 by Andy Karpov <andy.karpov@gmail.com>
*/

#include <VirtualWire.h>
#include <SoftwareServo.h>
#include <stdio.h>
#include <string.h>
#include "pitches.h"

SoftwareServo myservo;

const int rxPin = A1; // rx digital pin
const int txPin = A4; // redefined tx pin
const int pttPin = A5; // redefined ptt pin
const int rxSpeed = 2000; // radio unit speed

const int beepPin = 4; // buzzer pin
const int forwardPin = 2; // forward light pin
const int backwardPin = 3; // backward light pin
const int wheelPin = 7; // servo pin

const int motorAPin1 = 13; // motor A pin 1
const int motorAPin2 = 12; // motor A pin 2
const int motorASpeedPin = 5; // motor A speed pin (pwm)
const int motorBPin1 = 11; // motor B pin 1
const int motorBPin2 = 8; // motor B pin 2
const int motorBSpeedPin = 6; // motor B speed pin (pwm)

const int timeOut = 300; // rx timeout
const int toneDuration = 50; // tone duration on rx timeout
const int deadZone = 50; // dead zone from accelerometer

byte buf[4]; // rx buffer
byte buflen = 4; // rx buffer length

int xval = 0; // x value
int yval = 0; // y value
int rval = 0; // r value

byte btnForward = LOW; // forward button state
byte btnBackward = LOW; // backward button state
byte btnBeep = LOW; // beep button state

int motorADir = 1; // motor A direction (1 - forward, 0 - backward)
int motorASpeed = 0; // motor A speed (0..255)

int motorBDir = 1; // motor B direction (1 - forward, 0 - backward)
int motorBSpeed = 0; // motor B speed (0..255)

int lastMotorADir = 1;
int lastMotorASpeed = 0;
int lastMotorBDir = 1;
int lastMotorBSpeed = 0;

unsigned long lastReceived = 0; // last received message timestamp
unsigned long lastTone = 0; // last tone timestamp
boolean beepOn = false; // beeper on flag
int noSignal = 1; // no signal flag

long currTime = 0; // current millis
long lastRX = 0; // last rx millis
 
// SETUP routine
void setup()
{
  // set pin modes
  pinMode(rxPin, INPUT);

  pinMode(motorAPin1, OUTPUT);
  pinMode(motorAPin2, OUTPUT);
  pinMode(motorASpeedPin, OUTPUT);
  pinMode(motorBPin1, OUTPUT);
  pinMode(motorBPin2, OUTPUT);
  pinMode(motorBSpeedPin, OUTPUT);
  
  digitalWrite(motorAPin1, LOW);
  digitalWrite(motorAPin2, LOW);
  digitalWrite(motorBPin1, LOW);
  digitalWrite(motorBPin2, LOW);
  digitalWrite(motorASpeedPin, LOW);
  digitalWrite(motorBSpeedPin, LOW);
  
  pinMode(forwardPin, OUTPUT);
  pinMode(backwardPin, OUTPUT);
  pinMode(wheelPin, OUTPUT);

  myservo.attach(wheelPin);
   
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
  currTime = millis();
  
  // virtualwire message processing
  if (vw_get_message(buf, &buflen)) {
       
      // update last RX
      lastRX = currTime; 
    
       // get received values from RX module and decode them
      xval = buf[0];
      yval = buf[1];
      rval = buf[2];
      rval = map(rval, 0, 255, 159, 0);
      
       // get button values and decode them
       btnForward = (buf[3] & B00000100) ? HIGH : LOW;
       btnBackward= (buf[3] & B00001000) ? HIGH : LOW;
       btnBeep    = (buf[3] & B00010000) ? HIGH : LOW;
       
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
          
          if (yval >= 127 + deadZone) {
              motorADir = (motorBDir == 1) ? 0 : 1;
           } else if (yval <=127 - deadZone) {
              motorBDir = (motorADir == 1) ? 0 : 1;
           }
       } else {
          motorASpeed = 0;
          motorBSpeed = 0;
       }       
    noSignal = 0;  
  }
    
  if (currTime - lastRX > timeOut) {
       noSignal = 1;
       motorADir = 1;
       motorBDir = 1;
       motorASpeed = 0;
       motorBSpeed = 0;
       btnForward = 0;
       btnBackward = 0;
       btnBeep = 0;
  }
  
   // set motors direction   
   digitalWrite(motorAPin1, ((motorADir == 1) ? HIGH : LOW));
   digitalWrite(motorAPin2, ((motorADir == 1) ? LOW : HIGH));
   
   digitalWrite(motorBPin1, ((motorBDir == 1) ? HIGH : LOW));
   digitalWrite(motorBPin2, ((motorBDir == 1) ? LOW : HIGH)); 

   // set motors speed
   analogWrite(motorASpeedPin, motorASpeed);
   analogWrite(motorBSpeedPin, motorBSpeed);
   
   // todo: servo
   myservo.write(rval);
   
   delay(15);
   
   SoftwareServo::refresh();
   
   // remember previous motor state
   lastMotorASpeed = motorASpeed;
   lastMotorBSpeed = motorBSpeed;
   lastMotorADir = motorADir;
   lastMotorBDir = motorBDir;
   
   // set LEDs state
   digitalWrite(forwardPin, ((btnForward == 1) ? HIGH : LOW));
   digitalWrite(backwardPin, ((btnBackward == 1) ? HIGH : LOW));
   
   // beep cycle on rx timeout
   if (currTime - lastTone > toneDuration) {
      lastTone = currTime;
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
