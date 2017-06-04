#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>
#include <WaspSensorGas_v20.h>

char buffer [128];

char* sleepTime = "00:00:00:01";           

char data[100];     

float connectorAFloatValue; 
float connectorBFloatValue;  
float connectorCFloatValue;    
float connectorDFloatValue;   
float connectorEFloatValue;
float connectorFFloatValue;

int connectorAIntValue;
int connectorBIntValue;
int connectorCIntValue;
int connectorDIntValue;
int connectorEIntValue;
int connectorFIntValue;

char  connectorAString[10];  
char  connectorBString[10];   
char  connectorCString[10];
char  connectorDString[10];
char  connectorEString[10];
char  connectorFString[10];

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
    send_command("AT+ACK=8\n");

}

void format_frame(const char * text){
  char packet[11];
  char command[19];
  char temp_buffer[2];
  
  int packet_number = 1;
  temp_buffer[0] = packet_number;
  temp_buffer[1] = '\0';
  
  strcpy(packet,temp_buffer);

  int text_index = 0; //text index
  int packet_index = 1; //packet index
  int remaining_bytes = strlen(text);
  int completed_bytes = 0;
  USB.print("Formatting ");
  USB.print(strlen(text));
  USB.print(" bytes.\r\n");
  

  while(remaining_bytes > 0){
    //Update packet
    if(remaining_bytes > 10){
      strncat(packet, text + completed_bytes, 10);
      completed_bytes += 10;
      remaining_bytes -= 10; 
    } else{
      strncat(packet, text + completed_bytes, remaining_bytes);
      completed_bytes += 10;
      remaining_bytes = 0;
    }

    //send packet
    strcpy(command, "AT+SEND=");
    strcat(command, packet);
    strcat(command, "\n");

    /*USB.print("COMMAND > ");
    for(int k = 0; k < 19; k++){
      USB.print(command[k], DEC);
      USB.print(" ");
    }
    USB.print("\r\n");*/
    send_command(command);
        
    //reset packet & command
    memset(packet, 0, 11);
    memset(command, 0, 19);
    packet_number += 1;
    if(packet_number > 255){
      packet_number = 1;
    }
    
    temp_buffer[0] = packet_number;
    temp_buffer[1] = '\0';
    strcpy(packet,temp_buffer);
  }
}
void loop()
{   
    //Turn on the sensor board
    SensorGasv20.ON();
    //Turn on the RTC
    RTC.ON();
    //supply stabilization delay
    delay(100);

    // Step 9. Turn on the sensors

    delay(10000);

    //Turning on NO2 Sensor
    SensorGasv20.setSensorMode(SENS_ON, SENS_SOCKET3B);
    delay(30000);

    //Turning on and configuring O3 Sensor
    SensorGasv20.setSensorMode(SENS_ON, SENS_SOCKET2B);
    SensorGasv20.configureSensor(SENS_SOCKET2B, 1, 10);
    delay(30000);

    SensorGasv20.configureSensor(SENS_SOCKET4CO, 1, 100);

    // Step 10. Read the sensors

    //First dummy reading for analog-to-digital converter channel selection
    SensorGasv20.readValue(SENS_TEMPERATURE);

    //First dummy reading for analog-to-digital converter channel selection
    SensorGasv20.readValue(SENS_HUMIDITY);

    //Configure and turn on the CO2 sensor  
    SensorGasv20.configureSensor(SENS_CO2, 7);
    SensorGasv20.setSensorMode(SENS_ON, SENS_CO2);    
    delay(30000);
    //First dummy reading to set analog-to-digital channel
    SensorGasv20.readValue(SENS_CO2);
    
    // Configuring NO2 sensor
    SensorGasv20.configureSensor(SENS_SOCKET3B, 1, 2);
    delay(10);
    //First dummy reading to set analog-to-digital channel
    SensorGasv20.readValue(SENS_SOCKET3B);
    
    //First dummy reading to set analog-to-digital channel
    SensorGasv20.readValue(SENS_SOCKET2B);
    
    //First dummy reading to set analog-to-digital channel
    SensorGasv20.readValue(SENS_SOCKET4A);
    

  
    while(1){  
    // READ SENSORS

    //Sensor temperature reading
    connectorAFloatValue = SensorGasv20.readValue(SENS_TEMPERATURE);
    Utils.float2String(connectorAFloatValue, connectorAString, 2);
    
    //Sensor temperature reading
    connectorBFloatValue = SensorGasv20.readValue(SENS_HUMIDITY);
    Utils.float2String(connectorBFloatValue, connectorBString, 2);
    
    //  CO2 SENSOR
    connectorCFloatValue = SensorGasv20.readValue(SENS_CO2);  
    Utils.float2String(connectorCFloatValue, connectorCString, 2);

    // NO2 SENSOR
    connectorDFloatValue = SensorGasv20.readValue(SENS_SOCKET3B);    
    Utils.float2String(connectorDFloatValue, connectorDString, 2);

    // SOCKET2B
    connectorEFloatValue = SensorGasv20.readValue(SENS_SOCKET2B);    
    Utils.float2String(connectorEFloatValue, connectorEString, 2);

    // SOCKET4C0
    connectorFFloatValue = SensorGasv20.readValue(SENS_SOCKET4CO);    
    Utils.float2String(connectorFFloatValue, connectorFString, 2);


    // TURN OFF SENSORS
    //SensorGasv20.setSensorMode(SENS_OFF, SENS_CO2); 
    //SensorGasv20.setSensorMode(SENS_OFF, SENS_SOCKET3B);
    //SensorGasv20.setSensorMode(SENS_OFF, SENS_SOCKET2B);
    
    //
    //Data payload composition
    sprintf(data,"%lu %s %s %s %s %s %s~",
     RTC.getEpochTime(),
     connectorAString,
     connectorBString,
     connectorCString,
     connectorDString,
     connectorEString,
     connectorFString);
   
    format_frame(data);
    
    delay(30000);
    }
}
