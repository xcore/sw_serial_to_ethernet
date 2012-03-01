// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename: app_manager.xc
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file implements state machine to handle http requests and
connection state management and functionality to interface http client
(mainly application and uart channels configuration) data
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include "user_client.h"
#include "xtcp_client.h"
#include "app_manager.h"
#include "telnet_app.h"
#include "stdio.h"
#include "stdlib.h"
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
/* CONFIG CMD FROM USER CLIENTS */
#define CONFIG_KEY_WORD_LEN				3
#define NUM_CONFIG_PARAM				8
#define CONFIG_PARAM_LEN				7
#define CONFIG_DATA_LEN					(NUM_CONFIG_PARAM * CONFIG_PARAM_LEN)

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
/** User actions type.
 *  The event type represents list of actions that shall be validated from
 *  user clients
 *
 **/
typedef enum user_action_state_t {
	NO_PENDING_USER_ACTION = 0,
	PENDING_USER_ACTION,
	PARSE_USER_DATA,
	USER_DATA_INVALID,
} user_action_state_t;

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
s_user_client_cmd_response	user_client_cmd_resp;

user_action_state_t gPending_usr_action;
char config_key_word[CONFIG_KEY_WORD_LEN]="#C";
char gUsr_Config_KeyWord[CONFIG_KEY_WORD_LEN];
char gUser_data_unparsed[CONFIG_DATA_LEN];
s_uart_channel_config	client_uart_channel_config;
s_uart_channel_config	uart_channel_config_backup;

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

unsigned int validate_uart_params()
{
	if (client_uart_channel_config.channel_id >= UART_RX_CHAN_COUNT)
	{
		return 0;
	}
	else if ((client_uart_channel_config.char_len < 5) ||
			(client_uart_channel_config.char_len > 8))
	{
		return 0;
	}

	return 1;
}

void default_usage()
{
	/* In any case, reset the buffer */
	gUsr_Config_KeyWord[0] = '\0';

	/* Error in input config string */
	user_client_cmd_resp.pending_user_cmd_response = 1;
	sprintf(user_client_cmd_resp.user_resp_buffer, "%s","Error in config command. Press '@' to reset. \
			Usage: #C#P1#P2#P3#P4#P5#P6#P7#@  where C is Uart Config; P1 => Uart Channel[0 to 7]; \
			P2 => Parity[0 to 3]; P3 => Stop Bits [None/One]; P4 => Baud[115200, 57600, 19200]; P5 => Uart Char len [5 to 8] \
			P6 => Polarity; P7 => Telnet Port");
}

/** =========================================================================
*  parse_user_data_from_client
*
*  This function stores various uart parameters from telnet client
*
*  \param char data : data from client
*
*  \return			None
*
**/
static void parse_user_data_from_client(char data)
{
	static int data_index;
	int i = 0;
	int channel_id;
	//int chnl_config_status = 0;

	if (data == '@')
	{
		/* End of config data - parse and store to app structure */
		int param_id = 0;
		int j=0;
		int marker = 0;
		char gTelnet_uart_config_data_parsed[NUM_CONFIG_PARAM][CONFIG_PARAM_LEN] = {""};

		printstrln("Hit End of conf data. Now parsing...");
		/* Parse the data for its parameters */
		for (i=0;i<=data_index;i++)
		{
			if (gUser_data_unparsed[i] == '#')
			{
				marker++;
				if (2 == marker)
				{
					//gTelnet_uart_config_data_parsed[param_id][j] = '\0';
					/* go to the next parameter */
					param_id++;
					/* reset marker 'to 1' bcoz initial marker is no more repetitive*/
					marker = 1;
					j = 0;
				}
			} //[if (gUser_data_unparsed[i] == '#')]
			else
			{
				gTelnet_uart_config_data_parsed[param_id][j] =
						gUser_data_unparsed[i];
				j++;
			}
		} //[for (i=0;i<=data_index;i++)]

		if (param_id == NUM_CONFIG_PARAM-1)
		{
			/* Apply the config */
	    	// Set configuration from the data available in config_structure
			param_id = 0;
			client_uart_channel_config.channel_id = atoi(gTelnet_uart_config_data_parsed[param_id++]);
			printstr("Channel id is: "); printintln(client_uart_channel_config.channel_id);
			client_uart_channel_config.parity      = atoi(gTelnet_uart_config_data_parsed[param_id++]);
	    	client_uart_channel_config.stop_bits   = atoi(gTelnet_uart_config_data_parsed[param_id++]);
	    	client_uart_channel_config.baud        = atoi(gTelnet_uart_config_data_parsed[param_id++]);
	    	client_uart_channel_config.char_len    = atoi(gTelnet_uart_config_data_parsed[param_id++]);
	    	client_uart_channel_config.polarity    = atoi(gTelnet_uart_config_data_parsed[param_id++]);
	    	client_uart_channel_config.telnet_port = atoi(gTelnet_uart_config_data_parsed[param_id++]);
			if (0 == validate_uart_params())
			{
				default_usage();
			}
			else // [if (0 == validate_uart_params())]
			{
				channel_id = client_uart_channel_config.channel_id;
				/* Backup the current valid params */
				uart_channel_config_backup.channel_id       = channel_id;
				uart_channel_config_backup.parity           = uart_channel_config[channel_id].parity;
				uart_channel_config_backup.stop_bits        = uart_channel_config[channel_id].stop_bits;
				uart_channel_config_backup.baud             = uart_channel_config[channel_id].baud;
				uart_channel_config_backup.char_len         = uart_channel_config[channel_id].char_len;
				uart_channel_config_backup.polarity         = uart_channel_config[channel_id].polarity;
				uart_channel_config_backup.telnet_port      = uart_channel_config[channel_id].telnet_port;
				uart_channel_config_backup.telnet_conn_id   = uart_channel_config[channel_id].telnet_conn_id;

		    	/* Modify the config structure with new values */
		    	uart_channel_config[channel_id].parity      = client_uart_channel_config.parity;
		    	uart_channel_config[channel_id].stop_bits   = client_uart_channel_config.stop_bits;
		    	uart_channel_config[channel_id].baud        = client_uart_channel_config.baud;
		    	uart_channel_config[channel_id].char_len    = client_uart_channel_config.char_len;
		    	uart_channel_config[channel_id].polarity    = client_uart_channel_config.polarity;
		    	uart_channel_config[channel_id].telnet_port = client_uart_channel_config.telnet_port;

//#ifdef DEBUG_LEVEL_3
		    	printintln(uart_channel_config[channel_id].channel_id);
		    	printintln((int)uart_channel_config[channel_id].parity);
		    	printintln((int)uart_channel_config[channel_id].stop_bits);
		    	printintln((int)uart_channel_config[channel_id].baud);
		    	printintln((int)uart_channel_config[channel_id].char_len);
		    	printintln((int)uart_channel_config[channel_id].polarity);
		    	printintln((int)uart_channel_config[channel_id].telnet_port);
//#endif //DEBUG_LEVEL_3

#if 0 //TODO: TBR
		    	//uart_tx_reconf_pause( cTxUART, t );
		    	//uart_rx_reconf_pause( cRxUART );

		    	chnl_config_status = configure_uart_channel(channel_id);

		    	//uart_tx_reconf_enable( cTxUART );
		    	//uart_rx_reconf_enable( cRxUART );
		    	if (0 != chnl_config_status)
				{
			    	user_client_cmd_resp.pending_user_cmd_response = 1;
			    	sprintf(user_client_cmd_resp.user_resp_buffer, "%s%d%s%s","Config setting for Uart Channel ", channel_id, " Failed. ", "Reverting the channel config");
			    	{
				    	/* Modify the config structure with backup values */
				    	uart_channel_config[channel_id].parity      = uart_channel_config_backup.parity;
				    	uart_channel_config[channel_id].stop_bits   = uart_channel_config_backup.stop_bits;
				    	uart_channel_config[channel_id].baud        = uart_channel_config_backup.baud;
				    	uart_channel_config[channel_id].char_len    = uart_channel_config_backup.char_len;
				    	uart_channel_config[channel_id].polarity    = uart_channel_config_backup.polarity;
				    	//uart_channel_config[channel_id].telnet_port = uart_channel_config_backup.telnet_port;

				    	//uart_tx_reconf_pause( cTxUART, t );
				    	//uart_rx_reconf_pause( cRxUART );

				    	//chnl_config_status = configure_uart_channel(channel_id);

				    	//uart_tx_reconf_enable( cTxUART );
				    	//uart_rx_reconf_enable( cRxUART );
			    	}
				} //[if (0 != chnl_config_status)]
				else
#endif //TODO: TBR
				{
			        uart_channel_config[channel_id].is_configured = TRUE;
			        if (uart_channel_config[channel_id].telnet_port !=
			        		uart_channel_config_backup.telnet_port)
			        {
			        	uart_channel_config[channel_id].telnet_conn_id = 0;
			            uart_channel_config[channel_id].is_telnet_active = FALSE;
			        }

			        telnet_conn_details.channel_id = channel_id;
		            telnet_conn_details.prev_telnet_conn_id = uart_channel_config_backup.telnet_conn_id;
		            telnet_conn_details.prev_telnet_port = uart_channel_config_backup.telnet_port;
		            telnet_conn_details.pending_config_update = 1;

					user_client_cmd_resp.pending_user_cmd_response = 1;
			    	sprintf(user_client_cmd_resp.user_resp_buffer, "%s %d %s","Config setting for Uart Channel", channel_id, " Successful");
				}  //[if (0 != chnl_config_status)]
			} // [if (0 == validate_uart_params())]
		} //[if (param_id == NUM_CONFIG_PARAM-1)]
		else
		{
			user_client_cmd_resp.pending_user_cmd_response = 1;
	    	sprintf(user_client_cmd_resp.user_resp_buffer, "%s","Invalid config params");
		} //[if (param_id == NUM_CONFIG_PARAM-1)]

    	/* In any case, reset the buffer */
		gPending_usr_action = NO_PENDING_USER_ACTION;
		gUsr_Config_KeyWord[0] = '\0';

		/* Reset local data index pointer */
		data_index = 0;
	} //[if (data == '@')]
	else
	{
		if (data_index < CONFIG_DATA_LEN)
		{
			gUser_data_unparsed[data_index] = data;
			data_index++;
		} //[if (data_index < CONFIG_DATA_LEN)]
		else
		{
			/* Reset local data index pointer */
			data_index = 0;

			user_client_cmd_resp.pending_user_cmd_response = 1;
			sprintf(user_client_cmd_resp.user_resp_buffer, "%s","Invalid user data");

			gPending_usr_action = USER_DATA_INVALID;
			gUsr_Config_KeyWord[0] = '\0';
		} //[if (data_index < CONFIG_DATA_LEN)]
	} //[if (data == '@')]

}

/** =========================================================================
*  parse_client_usr_command
*
*  This function fetches the data from the telnet client, parses it to
*  identify uart key word to identify different user actions
*
*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			None
*
**/
void parse_client_usr_command(char data)
{
	static int local_data_index;

	if (data == '#')
	{
		/* There is a possible user action request */
		if (NO_PENDING_USER_ACTION == gPending_usr_action)
		{
			/* Set pending request */
			gPending_usr_action = PENDING_USER_ACTION;
			printstrln("Hit 1");
		}
	}

	if (PENDING_USER_ACTION == gPending_usr_action)
	{
		/* Store telnet data for config key word request */
		gUsr_Config_KeyWord[local_data_index] = data;
		local_data_index++;
		if (local_data_index == (CONFIG_KEY_WORD_LEN-1))
		{
			int i = 0;
			int j = 0;

			/* Reset local index pointer */
			local_data_index = 0;

			/* Received key word len; Check if it is a config request */
			for (i=0; i<(CONFIG_KEY_WORD_LEN-1); i++)
			{
				if (gUsr_Config_KeyWord[i] != config_key_word[i])
				{
					break;
				}
				else
				{
					j++;
				}
			}

			if (j == (CONFIG_KEY_WORD_LEN-1))
			{
				/* This is cconfirmed to be a uart config request from telnet;
				 * Parse the telnet config data */
				gPending_usr_action = PARSE_USER_DATA;
				printstrln("Hit 2");
			}
			else
			{
				/* This is not a config request;
				 * Send error message to the client */
				gPending_usr_action = USER_DATA_INVALID;
				printstrln("Not a conf key word");
			}
		}
	}
	else if (PARSE_USER_DATA == gPending_usr_action)
	{
		parse_user_data_from_client(data);
	}
	else if (USER_DATA_INVALID == gPending_usr_action)
	{
		static int emitFlag = 0;

		/* Error in input config string */
		if (0 == emitFlag)
		{
			emitFlag = 1;

			user_client_cmd_resp.pending_user_cmd_response = 1;
			sprintf(user_client_cmd_resp.user_resp_buffer, "%s","Error in config command. Console is locked. Press '@' to reset.");
		}

		if (data == '@')
		{
			gPending_usr_action = NO_PENDING_USER_ACTION;
			emitFlag = 0;

			user_client_cmd_resp.pending_user_cmd_response = 1;
			sprintf(user_client_cmd_resp.user_resp_buffer, "%s","Console is released. Enter the appropriate command");
		}
	}
	else
	{
		gPending_usr_action = USER_DATA_INVALID;
	}
}
