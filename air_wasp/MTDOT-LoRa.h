/*
 *  Header file for MTDOTLORA
 *
 *
 */

#ifndef __MTDOTLORA_H__
#define __MTDOTLORA_H__

/**
 * Sets the LoRa module up.
 * @return 0 if setup was successful, 1 if it failed.
 */
int mtdotlora_setup();

/**
 * Sends a command to the LoRa module.
 * @param  command The AT command to be sent. Must terminate with linebreak.
 * @return         0 if command returned OK, 1 if an error occurred.
 */
int mtdotlora_send_command(const char * command);

/**
 * Sends text over LoRa. If necessary, the text is broken up into multiple packets.
 * @param text Text to be sent.
 * @return         0 if command returned OK, 1 if an error occurred
 */
int mtdotlora_send_text(const char * text);

#endif
