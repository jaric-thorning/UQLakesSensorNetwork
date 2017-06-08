#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>
#include <WaspSensorGas_v20.h>
#include <stdlib.h>

#include "MTDOT-LoRa.h"

char* sleepTime = "00:00:00:10"; //NOTE: there is an aproximately 3 minute setup time
char* setup_sleepTime = "00:00:00:10";

char data[100];

char filename[]="log.txt";

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

int setup_attempts = 0;

void setup()
{
  //PWR.ifHibernate();
  USB.ON();
	PWR.setSensorPower(SENS_3V3, SENS_OFF);
	PWR.setSensorPower(SENS_5V, SENS_ON);
  USB.ON();
  SD.ON();
  SD.del(filename);
  SD.create(filename);
}

void loop()
{
  
  setup_attempts = 0;
  while(mtdotlora_setup() && setup_attempts < 3){
    setup_attempts++;
    delay(20000);
  }
  //Turn on the sensor board
  SensorGasv20.ON();
  //Turn on the RTC
  RTC.ON();
  // Step 9. Turn on the sensors
  delay(100);
    
  if(setup_attempts < 3){
 
  	delay(10000);
  
  	//Turning on NO2 Sensor
    USB.print("Turning on NO2 Sensor...\r\n");
  	SensorGasv20.setSensorMode(SENS_ON, SENS_SOCKET3B);
    
    // Configuring NO2 sensor
    USB.print("Configuring NO2 Sensor...\r\n");
    SensorGasv20.configureSensor(SENS_SOCKET3B, 1, 2);
    delay(10);
    //First dummy reading to set analog-to-digital channel
    SensorGasv20.readValue(SENS_SOCKET3B);
  	delay(30000);
  
  	//Turning on and configuring O3 Sensor
    USB.print("Turning on O3 Sensor...\r\n");
  	SensorGasv20.setSensorMode(SENS_ON, SENS_SOCKET2B);
    USB.print("Configuring O3 Sensor...\r\n");
  	SensorGasv20.configureSensor(SENS_SOCKET2B, 1, 10);
  	delay(30000);

    USB.print("Configuring CO Sensor...\r\n");
  	SensorGasv20.configureSensor(SENS_SOCKET4CO, 1, 100);
  
    //Configuring TEMP SENSOR
    USB.print("Configuring Temperature Sensor...\r\n");
  	//First dummy reading for analog-to-digital converter channel selection
  	SensorGasv20.readValue(SENS_TEMPERATURE);

    USB.print("Configuring Humidity Sensor...\r\n");
  	//First dummy reading for analog-to-digital converter channel selection
  	SensorGasv20.readValue(SENS_HUMIDITY);
  
  	//Configure and turn on the CO2 sensor
    USB.print("Turning on CO2 Sensor...\r\n");
    SensorGasv20.setSensorMode(SENS_ON, SENS_CO2);
    USB.print("Configuring CO2 Sensor...\r\n");
  	SensorGasv20.configureSensor(SENS_CO2, 7);
  	
  	delay(30000);
  	//First dummy reading to set analog-to-digital channel
  	SensorGasv20.readValue(SENS_CO2);
  
  	//First dummy reading to set analog-to-digital channel
  	SensorGasv20.readValue(SENS_SOCKET2B);
  
  	//First dummy reading to set analog-to-digital channel
  	SensorGasv20.readValue(SENS_SOCKET4A);

		// READ SENSORS
    while(1){
		//Sensor temperature reading
    USB.print("Reading Sensors...\r\n");
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
    //USB.print("Turning off sensors...\r\n");
		//SensorGasv20.setSensorMode(SENS_OFF, SENS_CO2);
		//SensorGasv20.setSensorMode(SENS_OFF, SENS_SOCKET3B);
		//SensorGasv20.setSensorMode(SENS_OFF, SENS_SOCKET2B);

		//
		//Data payload composition
		sprintf(data, "%lu,%s,%s,%s,%s,%s,%s~",
		        RTC.getEpochTime(),
		        connectorAString,  // TEMPERATURE
		        connectorBString,  // HUMIDITY
		        connectorCString,  // CO2
		        connectorDString,  // NO2
		        connectorEString,  // O3
		        connectorFString); // CO

  
    SD.append(filename, data);
    SD.append(filename, ",");
		if(mtdotlora_send_text(data)){
      USB.print("ERROR OCCURED, DATA NOT SENT CORRECTLY\n\r");
		} 
   
    }
    USB.print("Hibernating.\r\n");
    //delay(5000);
    //PWR.hibernate(sleepTime, RTC_OFFSET, RTC_ALM1_MODE2);
		delay(10000);
	} else{ //setup attempts >= 3
    USB.print("Reseting.\r\n");
    //delay(5000); 
    //PWR.hibernate(setup_sleepTime, RTC_OFFSET, RTC_ALM1_MODE2);
	}
  USB.print("Waking Up.\r\n");
}
