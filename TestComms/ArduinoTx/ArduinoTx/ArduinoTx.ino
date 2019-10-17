#include <nRF24L01.h>
#include <printf.h>
#include <RF24.h>
#include <RF24_config.h>

const int pinCE = 9;
const int pinCSN = 10;
RF24 radio(pinCE, pinCSN);

const uint64_t pipe = 0xDEADBEEF00LL;

char data[16] = "Hola mundo";

void setup() {
  radio.begin();
  radio.setDataRate( RF24_250KBPS );
  radio.openWritingPipe(pipe);
  
   Serial.begin(9600);
}

void loop() {
   radio.write(data, sizeof data);
   Serial.println("Enviando.. ");
   delay(1000);
}
