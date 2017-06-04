#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>

char buffer [128];

void send_command(const char * command){
    W232.send(command);
    
    char c;
    int cr_count = 0;
    while(cr_count < 3){
      delay(100); 
      int da = W232.available();
      if(da > 0){
        USB.print(da);
        USB.print(">");
        for(int i = 0; i < da; i++){
          c = W232.read();
          //USB.print(c, DEC);
          //USB.print(":");
          USB.print(c);
          //USB.print(" ");
          if(c == 10){
            cr_count++;
          }
        }
        
      }
    }
    USB.print("- - - - - - -\r\n");
}

void setup()
{
    PWR.setSensorPower(SENS_3V3,SENS_OFF);
    PWR.setSensorPower(SENS_5V,SENS_ON);

    //Switch mux to socket 0:
    W232.ON(SOCKET0);
    delay(100);

    W232.parityBit(NONE);
    W232.stopBitConfig(1);
    W232.baudRateConfig(115200);
    delay(300);


    //USB.print(".");
    //Connect to the UQ network:
    send_command("AT\n");
    send_command("AT&F\n");
    send_command("AT+FSB=7\n");
    send_command("AT+NI=1,UQ_St_Lucia\n");
    send_command("AT+NK=1,L0raStLucia\n");
    send_command("AT+JR=100\n");
    send_command("AT+JOIN\n");

    

}


void loop()
{   
    send_command("AT+SEND=~CSSE4011~\n");
   
    /*delay(1000);
    W232.send("AT\n");
    delay(100);
    check_reply();
    
    delay(1000);
    W232.send("AT+NJS\n");
    delay(100);
    check_reply();
    
    delay(1000);
    W232.send("AT+FREQ\n");
    delay(100);
    check_reply();

    /*W232.send("AT+SEND=lakesensing\n");
      USB.print("REPLY: ");
      while (W232.available()) {
         USB.print(W232.read());
    }*/
    
    //USB.printf("Loop counter: %d\n", i);
    /* W232.send("AT+DC\n");
     

     W232.send("AT+DI\n");
     while (W232.available()) {
         USB.print(W232.read());
     }
     USB.println("");

     W232.send("AT+SDR\n");
     while (W232.available()) {
         USB.print(W232.read());
     }*/

    

    delay(1000);
}
