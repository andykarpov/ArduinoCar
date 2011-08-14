/*

 ArduinoCar Transmitter Unit
 version 1.1
 
 Read X and Y value from accelerometer unit and a button states 
 (forward/backward/beep) and transmit these values through the 
 433 MHz transmitter (using VirtualWire library).
 
 Message data packed into the 9 bytes array:
 byte 0..3 - X value
 byte 4..7 - Y value 
 byte 8 - mixed data, each bit is a state, such as:
 - bit 0 - forward LED state ( 1 - HIGH, 0 - LOW)
 - bit 1 - backward LED state ( 1 - HIGH, 0 - LOW)
 - bit 2 - buzzer state ( 1 - play a buzz, 0 - silence) 
 
 Hardware:
 0. Arduino Nano (atmega 328)
 1. Accelerometer ADXL330 connected to +5V, GND, X to A7,Y to A6, Z to A2
 2. 4 green LEDs and 4 red LEDs connected to D4,D5,D6,D8 
    and D9,D10,D11,D12 through a 270 Ohm Resistors
 3. A 3 buttons between GND and A0, D2, D3, without an external pullup resistors
 4. A 433 Mhz transmitter unit connected to +5V, GND, D13 
 
 External dependencies: VirtualWire library 
 (www.open.com.au/mikem/arduino/VirtualWire.pdf)
 
 created  23 Jul 2011
 modified 14 Aug 2011
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
const int txSpeed = 2000; // tx speed

byte btnForward; // forward button state
byte btnBackward; // backward button state
byte btnBeep; // beep button state

int xval; // x-axis value passed from accelerometer
int yval; // y-azis value passed from accelerometer

byte message[9]; // packed record to transmit over a virtualwire link

// SETUP routine
void setup()
{
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

  // tx unit init
  vw_set_tx_pin(txPin); 
  vw_set_ptt_pin(pttPin);
  vw_set_rx_pin(rxPin);
  vw_setup(txSpeed);
}

// MAIN LOOP routine
void loop()
{
  // reading button states
  btnForward = (digitalRead(btnForwardPin) == LOW) ? HIGH : LOW;
  btnBackward = (digitalRead(btnBackwardPin) == LOW) ? HIGH : LOW;
  btnBeep = (digitalRead(btnBeepPin) == LOW) ? HIGH : LOW;
  
  // reading x value from the accelerometer
  xval = analogRead(xpin);

  // reading y value from the accelerometer
  yval = analogRead(ypin);

  // calculate led levels (0...ledCount)
  int ledLevelA = map(xval, -600, 600, 0, ledCount);
  int ledLevelB = map(yval, -600, 600, 0, ledCount);
  
  // loop over the LED array and turn on/off leds
  for (int thisLed = 0; thisLed < ledCount; thisLed++) {
    digitalWrite(ledPinsA[thisLed], (thisLed < ledLevelA) ? HIGH : LOW);
    digitalWrite(ledPinsB[thisLed], (thisLed < ledLevelB) ? HIGH : LOW);
  }

  char buf[4];
  
  // pack x val
  sprintf(buf, "%d", xval);
  message[0] = buf[0];
  message[1] = buf[1];
  message[2] = buf[2];
  message[3] = buf[3];
  

  // pack y val
  sprintf(buf, "%d", yval);
  message[4] = buf[0];
  message[5] = buf[1];
  message[6] = buf[2];
  message[7] = buf[3];

  // pack button states
  message[8] = ((btnForward == HIGH) ? 4 : 0) + 
               ((btnBackward == HIGH) ? 8 : 0) + 
               ((btnBeep == HIGH) ? 16: 0); 

  // Transmitting a message over RX channel
  vw_send(message, 9); // sending message
  vw_wait_tx(); // Wait until the whole message is gone
}
