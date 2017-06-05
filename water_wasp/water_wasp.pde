#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>

#include "MTDOT-LoRa.h"

#define NUMCOMMANDS 8
#define DEBUG 0
char buffer [128];
char data[200];
double Readings[9];
int skipLORASend;
/*
 * Writes an input string to serial port 1
 */
void serialStringWrite(char* str) {
    int commandLength = strlen(str);
    for (int i = 0; i < commandLength; i++) {
        serialWrite(str[i], 1);
    }
}

void setup()
{
    // Opening UART to show messages using 'Serial Monitor'
    USB.ON();
    delay(100);
    while(mtdotlora_setup()==1){
      
    }
    Utils.setMuxAux1(); // check the manual to find out where you connect the sensor
    beginSerial(9600, 1); //it may be that you need other baut rate
    serialStringWrite("setecho 0\r");
    delay(1000);
    serialStringWrite("setdelim 2\r");
    skipLORASend = 1;
}


void loop()
{
    int index = 0;
    serialStringWrite("data\r");
    delay(300);

    while (serialAvailable(1))
    {
        if (index < 127) {
            buffer[index] = serialRead(1);
            index ++;
        }

    }
    delay(1000);
    while (serialAvailable(1))
    {
        if (index < 127) {
            buffer[index] = serialRead(1);
            index ++;
        }
    }

    if (index > 0)
    {
        //USB.println("Data:");
        //Got data from other UART:
        buffer[index-1] = '\0';
        char testchar;
        int index = 0;
        sprintf(data, "%lu,%s~",
        RTC.getEpochTime(),buffer); // CO
        USB.println(buffer);
        if(!skipLORASend){
          mtdotlora_send_text(data);
        }
        else{
          skipLORASend = 0;
        }
    }


    delay(2000);
}
