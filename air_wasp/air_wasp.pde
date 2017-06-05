#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>
#include <WaspSensorGas_v20.h>
#include <stdlib.h>

#include "MTDOT-LoRa."


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


void setup()
{
	PWR.setSensorPower(SENS_3V3, SENS_OFF);
	PWR.setSensorPower(SENS_5V, SENS_ON);

	while (mtdotlora_setup() == 1) {}
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


	while (1) {
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
		sprintf(data, "%lu,%s,%s,%s,%s,%s,%s~",
		        RTC.getEpochTime(),
		        connectorAString,  // TEMPERATURE
		        connectorBString,  // HUMIDITY
		        connectorCString,  // CO2
		        connectorDString,  // NO2
		        connectorEString,  // O3
		        connectorFString); // CO

		mtdotlora_send_text(data);

		delay(30000);
	}
}
