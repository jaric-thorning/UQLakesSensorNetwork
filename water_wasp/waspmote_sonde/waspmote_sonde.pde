#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>

#define NUMCOMMANDS 8
char buffer [128];
double Readings[9];

void serialStringWrite(char* str){
  int commandLength = strlen(str);
  for(int i = 0; i < commandLength; i++){
    serialWrite(str[i],1);
  }
}
void setup()
{
    // Opening UART to show messages using 'Serial Monitor'
    USB.ON();

    //W232.ON(1);
    //W232.ON(1);
    delay(100);

/*
    W232.parityBit(DISABLED);
    W232.stopBitConfig(ONE_STOP_BIT);
    //W232.baudRateConfig(9600);
    W232.baudRateConfig(9600);
    delay(300);
    */
    Utils.setMuxAux1(); // check the manual to find out where you connect the sensor
    beginSerial(9600,1); //it may be that you need other baut rate
    //USB.println("Started.");
    serialStringWrite("setecho 0\r");
}

void loop()
{
    int index = 0; 
    //W232.send("data\n");
    serialStringWrite("data\r");
 /*   while(!W232.available()){
      //wait for some data to be sent back through to us by the exosonde
    }
    */
    delay(300);
    
    while (serialAvailable(1))
    {
        if(index < 127){
          buffer[index] = serialRead(1);
          index ++;      
        }

    }
    delay(1000);
        while (serialAvailable(1))
    {
        if(index < 127){
          buffer[index] = serialRead(1);
          index ++;      
        }

    }

    if (index > 0)
    {
        //USB.println("Data:");
        //Got data from other UART:
        buffer[index] = '\n';
        index++;
        buffer[index] = '\0';
        char testchar;
        int index = 0;
        int spacecounter = 0;
        testchar = buffer[index];
        while(spacecounter < NUMCOMMANDS){
          if(testchar == ' '){
            buffer[index] = ',';
            spacecounter++;
          }
          index++;
          testchar = buffer[index];
        }
          USB.print(buffer);
        
        
    }


    delay(2000);
}
