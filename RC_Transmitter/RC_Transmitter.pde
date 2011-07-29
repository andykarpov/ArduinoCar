/*

 RC Car Transmitter Unit
 version 1.0
 
 The idea: allow to control a car without touching any buttons, 
 just to change an angle of RC unit car will turn left/right/forward/backward.
 
 Hardware:
 0. Arduino Nano (atmega 328)
 1. Accelerometer ADXL330 connected to +5V, GND, X to A6,Y to A7
 2. 4 green LEDs and 4 red LEDs connected to D4,D5,D6,D8 and D9,D10,D11,D12 through a 220 Ohm Resistors
 3. 3 buttons between GND and A0, D2, D3, without an external pullup resistors
 4. A 433 Mhz transmitter unit connected to +5V, GND, A1 
 
 External dependencies: VirtualWire library (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created 23 Jul 2011
 by Andy Karpov <andy.karpov@gmail.com>
*/

#include <VirtualWire.h>
#include <stdio.h>
#include <string.h>

const int xpin = A7; // x-axis of the accelerometer
const int ypin = A6; // y-axis
const int zpin = A2; // z-axis

const int ledCount = 4; // led count per motor
const int ledPinsA[] = {9,10,11,12}; // leds for motor A
const int ledPinsB[] = {4,5,6,8}; // leds for motor B

const int btnForwardPin = A0; // forward button pin
const int btnBackwardPin = 3; // backward button pin
const int btnBeepPin = 2; // beep button pin

const int txPin = 13; // transmitter pin
const int rxPin = A1; // redefine rx pin
const int pttPin = A3; // redefine ptt pin

byte btnForward; // forward button state
byte btnBackward; // backward button state
byte btnBeep; // beep button state

int xval; // x-axis value passed from accelerometer
int yval; // y-azis value passed from accelerometer

byte motorADir; // motor A direction (1 - forward, 0 - backward)
byte motorASpeed; // motor A speed (0..255)

byte motorBDir; // motor B direction (1 - forward, 0 - backward)
byte motorBSpeed; // motor B speed (0..255)

byte message[3]; // packed record to transmit over a virtualwire link

void setup()
{
  // initialize the serial communications (debug to serial)
  // Serial.begin(9600);

  // initial values for motor speed and directions
  motorADir = 1;
  motorASpeed = 0;
  motorBDir = 1;
  motorBSpeed = 0;

  // set pin mode for accelerometer pins
  pinMode(xpin, INPUT);
  pinMode(ypin, INPUT);

  // loop over the led pin array and set them all to output:
  for (int thisLed = 0; thisLed < ledCount; thisLed++) {
    pinMode(ledPinsA[thisLed], OUTPUT);
    pinMode(ledPinsB[thisLed], OUTPUT); 
  }

  // set buttons pin mode to input
  pinMode(btnForwardPin, INPUT);
  pinMode(btnBackwardPin, INPUT);
  pinMode(btnBeepPin, INPUT);

  // enable internal pullups on button pins
  digitalWrite(btnForwardPin, HIGH);
  digitalWrite(btnBackwardPin, HIGH);
  digitalWrite(btnBeepPin, HIGH);

  vw_set_tx_pin(txPin); // tx pin different from default
  vw_set_ptt_pin(pttPin);
  vw_set_rx_pin(rxPin);
  vw_set_ptt_inverted(true); // not confirmed requirement
  // Initialise the IO and ISR
  vw_setup(2000); // bits per sec
}

void loop()
{
  // reading x: transform 580...440 to -255...255, 0 = 515-518
  xval = map(constrain(analogRead(xpin), 440, 580), 440, 580, -255, 255);
  
  // reading y: transform 440...580 to -255...255, 0 = 480-504
  yval = map(constrain(analogRead(ypin), 440, 580), 440, 580, -255, 255);

  // exclude range from -100 to 100
  if (xval >= -100 and xval <= 100) xval = 0;
  if (yval >= -100 and yval <= 100) yval = 0;

  // calculate motors direction
  if (xval >= 0) {
     motorADir = 1;
     motorBDir = 1;
  } else {
     motorADir = 0;
     motorBDir = 0;
  }
  
  // calculate motors speed
  motorASpeed = abs(xval);
  motorBSpeed = abs(xval);
  
  // adjust motors speed
  if (yval < 0) {
     motorASpeed = motorASpeed - constrain(abs(yval), 0, motorASpeed);
  }
  if (yval > 0) {
     motorBSpeed = motorBSpeed - constrain(abs(yval), 0, motorBSpeed);
  }

  // calculate led levels (0...ledCount)
  byte ledLevelA = map(motorASpeed, 0, 255, 0, ledCount);
  byte ledLevelB = map(motorBSpeed, 0, 255, 0, ledCount);
  
  // loop over the LED array and turn on/off leds
  for (int thisLed = 0; thisLed < ledCount; thisLed++) {
    if (thisLed < ledLevelA) {
      digitalWrite(ledPinsA[thisLed], HIGH);
    } 
    else {
      digitalWrite(ledPinsA[thisLed], LOW); 
    }

    if (thisLed < ledLevelB) {
      digitalWrite(ledPinsB[thisLed], HIGH);
    } 
    else {
      digitalWrite(ledPinsB[thisLed], LOW); 
    }
  }

  // reading buttons
  btnForward = digitalRead(btnForwardPin);
  btnBackward = digitalRead(btnBackwardPin);
  btnBeep = digitalRead(btnBeepPin);

  // pack message
  message[0] = motorASpeed;
  message[1] = motorBSpeed;
  message[2] = motorADir + motorBDir*2 + ((btnForward == LOW) ? 4 : 0) + ((btnBackward == LOW) ? 8 : 0) + ((btnBeep == LOW) ? 16: 0); // using 5 bits of 8

  // do some debug:
/*  Serial.print(xval);
  Serial.print(":");  
  Serial.print(yval);
  Serial.print("\t");
  Serial.print("A:");
  Serial.print(motorADir);
  Serial.print(":");
  Serial.print(motorASpeed);
  Serial.print("\t");
  Serial.print("B:");
  Serial.print(motorBDir);
  Serial.print(":");
  Serial.print(motorBSpeed);
  Serial.print("\t");
  Serial.print("FW:");
  Serial.print((btnForward == HIGH) ? 1 : 0);
  Serial.print(":BW:");
  Serial.print((btnBackward == HIGH) ? 1 : 0);
  Serial.print("BE:");
  Serial.print((btnBeep == HIGH) ? 1 : 0);
  Serial.println();
*/

  // Transmitting a message over RX channel
  vw_send(message, 3); // sending message
  vw_wait_tx(); // Wait until the whole message is gone
}

