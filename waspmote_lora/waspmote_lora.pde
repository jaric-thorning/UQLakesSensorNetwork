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
    send_command("AT+AP=4\n");

}

void format_frame(const char * text){
  char packet[10];
  char command[19];
  
  
  packet[0] = 0;
  packet[1] = 'T';
  packet[2] = 'T';

  int text_index = 0; //text index
  int packet_index = 3; //packet index
  int remaining_bytes = strlen(text);
  int completed_bytes = 0;
  USB.print("Formatting ");
  USB.print(strlen(text));
  USB.print(" bytes.\r\n");

  while(remaining_bytes > 0){
    //Update packet
    if(remaining_bytes > 10){
      strncpy(packet, text + completed_bytes, 10);
      completed_bytes += 10;
      remaining_bytes -= 10; 
    } else{
      strncpy(packet, text + completed_bytes, remaining_bytes);
      completed_bytes += 10;
      remaining_bytes = 0;
    }

    //send packet
    strcpy(command, "AT+SEND=");
    strcat(command, packet);
    strcat(command, "\n");

    send_command(command);
    
    //USB.print("Command formatted > ");
    //USB.print(command);
    //USB.print("\r\n");
        
    //reset packet & command
    packet_index = 3;
    memset(packet, 0, 11);
    memset(command, 0, 19);
    packet[0] = 0;
    packet[1] = 'T';
    packet[2] = 'T';
  }
}
void loop()
{   
    send_command("AT+SEND=0123456789A\n");
    format_frame("This is some data, hello world!");
    delay(1000);
}
