#include <nRF24L01.h>
#include <printf.h>
#include <RF24.h>
#include <RF24_config.h>

const int pinCE = 9;
const int pinCSN = 10;
RF24 radio(pinCE, pinCSN);

const uint64_t pipe = 0xDEADBEEF00LL;

char data[16] = "Hola mundo";
char receivedChar;

char cmd[20] ="";
int cmd_len = 0;

uint8_t isSend;

union {
  struct __attribute__((packed)) {
    uint8_t tag;
    uint8_t len;
    uint8_t data[30];
  } packet;
  uint8_t raw[32];
} command;

void setup() {
  radio.begin();
  radio.setDataRate( RF24_250KBPS );
  radio.openWritingPipe(pipe);
  cmd_len = 0;
   Serial.begin(19200);
   
}

void loop() {
  if (Serial.available() > 0) {
        receivedChar = Serial.read();
        cmd[cmd_len] = receivedChar;
        //Serial.print("Recibido: ");
        //Serial.println(receivedChar);

        cmd_len++;
        //Serial.print("Len: ");
        //Serial.println(cmd_len);
        if( cmd_len > 1){
          if ( (cmd_len) == cmd[1]+2 )
            isSend = true;
        }
        /*memset(&command, 0, 32);
        isSend = true;
        switch(receivedChar){
          case 'n':
            command.packet.tag = 0;
            command.packet.len = 1;
            command.packet.data[0] = 1;
            break;
          case 'f' : 
            command.packet.tag = 0;
            command.packet.len = 1;
            command.packet.data[0] = 0;
            break;
         case 't' : 
            command.packet.tag = 1;
            command.packet.len = 1;
            while(Serial.available() == 0);
            command.packet.data[0] = Serial.read();
            break;
          default:
            isSend = false;
            break;
        }*/
        if(isSend){
          radio.write(cmd, cmd_len);
          cmd_len = 0;
          isSend = false;
        }
    }
  
   //delay(1000);
}
