/*
 *    MTDOTLORA
 *
 *
 */
#include <Wasp232.h>
#include <inttypes.h>
#include <String.h>
#include <WaspSensorGas_v20.h>
#include <stdlib.h>

#include "MTDOT-LoRa.h"

char rtn_1[200];
char rtn_2[200];
char rtn_3[200];
char rtn_4[200];
char retry_count_char[10];

int mtdotlora_setup(void) {
	//Switch mux to socket 0:
	W232.ON(SOCKET0);
	delay(100);

	W232.parityBit(NONE);
	W232.stopBitConfig(1);
	W232.baudRateConfig(115200);
	delay(300);

	int error_occurred = 0;
	int setup_not_cleared = 0;
	//USB.print(".");
	//Connect to the UQ network:
	mtdotlora_send_command("AT\n");
	setup_not_cleared += mtdotlora_send_command("AT&F\n");
	setup_not_cleared += mtdotlora_send_command("AT+FSB=7\n");
	setup_not_cleared += mtdotlora_send_command("AT+NI=1,UQ_St_Lucia\n");
	setup_not_cleared += mtdotlora_send_command("AT+NK=1,L0raStLucia\n");
	setup_not_cleared += mtdotlora_send_command("AT+JR=100\n");
	setup_not_cleared += mtdotlora_send_command("AT+JOIN\n");
	setup_not_cleared += mtdotlora_send_command("AT+AP=4\n");
	setup_not_cleared += mtdotlora_send_command("AT+ACK=8\n");

	if (setup_not_cleared) {
		USB.print("Setup failed ");
		USB.print(setup_not_cleared);
		USB.print(" commands\n\r");
		
		return 1;
	} else {
		USB.print("Setup cleared.\n\r");
	}

	return 0;
}

int mtdotlora_send_command(const char * command) {
	W232.send(command);
	memset(rtn_1, 0, 200);
	memset(rtn_2, 0, 200);
	memset(rtn_3, 0, 200);
	memset(rtn_4, 0, 200);
	strcpy(rtn_1, "");
	strcpy(rtn_2, "");
	strcpy(rtn_3, "");
	strcpy(rtn_4, "");

	int rtn_value = 0;

	char temp_buffer[2];
	char c;
	int cr_count = 0;
	while (cr_count < 3) {
		delay(100);
		int da = W232.available();
		if (da > 0) {
			//USB.print(da);
			//USB.print(">");
			for (int i = 0; i < da; i++) {
				c = W232.read();
				//USB.print(c, DEC);
				//USB.print(":");
				USB.print(c);
				//USB.print(" ");
				if (c == 10) {
					cr_count++;
				} else if (c != 13) {
					temp_buffer[0] = c;
					temp_buffer[1] = '\0';
					if (cr_count == 0) {
						strcat(rtn_1, temp_buffer);
					} else if (cr_count == 1) {
						strcat(rtn_2, temp_buffer);
					} else if (cr_count == 2) {
						strcat(rtn_3, temp_buffer);
					} else if (cr_count == 3) {
						strcat(rtn_4, temp_buffer);
					}
				}
			}

		}
	}
	USB.print("- - - - - - -\r\n");

	//PROCESS RETURN STRINGS
	if (cr_count == 4) { //return should be in rtn_4
		if (strcmp(rtn_4, "OK") != 0) {
			rtn_value = 1;
		} else {
			rtn_value = 0;
		}
	} else if (cr_count == 3) { //return should be in rtn_3
		if (strcmp(rtn_3, "OK") != 0) {
			rtn_value = 1;
		} else {
			rtn_value = 0;
		}
	}

	return rtn_value;
}


int mtdotlora_send_text(const char * text) {
	char packet[11];
	char command[19];
	char temp_buffer[2];

	int packet_number = 1;
	temp_buffer[0] = packet_number;
	temp_buffer[1] = '\0';

	strcpy(packet, temp_buffer);

	int text_index = 0; //text index
	int packet_index = 1; //packet index
	int remaining_bytes = strlen(text);
	int completed_bytes = 0;
	USB.print("Formatting ");
	USB.print(strlen(text));
	USB.print(" bytes.\r\n");
  int error_occured = 0;

	while (remaining_bytes > 0) {
		//Update packet
		if (remaining_bytes > 10) {
			strncat(packet, text + completed_bytes, 10);
			completed_bytes += 10;
			remaining_bytes -= 10;
		} else {
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
    
    int retry_count = 0;
    SD.append("log.txt", command);
    SD.append("log.txt", ",");
		while(mtdotlora_send_command(command) && (retry_count < 3)){
		  retry_count++;
		}
   if(retry_count >= 3){
    error_occured = 1;
   }
   sprintf(retry_count_char, "%d", retry_count);
   SD.append("log.txt", retry_count_char);
   SD.append("log.txt", ",");

		//reset packet & command
		memset(packet, 0, 11);
		memset(command, 0, 19);
		packet_number += 1;
		if (packet_number > 255) {
			packet_number = 1;
		}

		temp_buffer[0] = packet_number;
		temp_buffer[1] = '\0';
		strcpy(packet, temp_buffer);
	}
  return error_occured;
}

