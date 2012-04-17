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
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "app_manager.h"
#include "debug.h"
#include "common.h"


/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
#define	MAX_BIT_RATE					115200 //100000		//bits per sec
#define TIMER_FREQUENCY					100000000	//100 Mhz
/* Default length of a uart character in bits */
#define	DEF_CHAR_LEN					8
//#define MGR_TX_TMR_EVENT_INTERVAL		(TIMER_FREQUENCY /	\
//										(MAX_BIT_RATE * UART_TX_CHAN_COUNT))
#define MGR_TX_TMR_EVENT_INTERVAL		4000 //500
#define MGR_RX_TMR_EVENT_INTERVAL		8000 //500 //TODO: Needs to be based on calculation
/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
typedef struct STRUCT_CMD_DATA
{
//	int   flag;
//	int   cmd_type;  //For future use
	int   uart_id;
} s_pending_cmd_to_send;
/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
s_uart_channel_config	uart_channel_config[UART_TX_CHAN_COUNT];
s_uart_tx_channel_fifo	uart_tx_channel_state[UART_TX_CHAN_COUNT];
s_uart_rx_channel_fifo	uart_rx_channel_state[UART_RX_CHAN_COUNT];
s_pending_cmd_to_send   pending_cmd_to_send;
/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  uart_channel_init
*
*  Initialize Uart channels data structure
*
*  \param		None
*
*  \return		None
*
**/
static void uart_channel_init(void)
{
  int i;
#ifdef SET_VARIABLE_BAUD_RATE
  int baud_rate = MAX_BIT_RATE;
  int baud_rate_reset = 0;
#endif //SET_VARIABLE_BAUD_RATE

  for (i=0;i<UART_TX_CHAN_COUNT;i++)
    {
	  // Initialize Uart channels configuration data structure
	  uart_channel_config[i].channel_id = i;
	  uart_channel_config[i].parity = even;
	  uart_channel_config[i].stop_bits = sb_1;
#ifdef SET_VARIABLE_BAUD_RATE
	  uart_channel_config[i].baud = baud_rate;
#else //SET_VARIABLE_BAUD_RATE
	  uart_channel_config[i].baud = MAX_BIT_RATE;
#endif //SET_VARIABLE_BAUD_RATE
	  uart_channel_config[i].char_len = DEF_CHAR_LEN;
	  uart_channel_config[i].polarity = start_0;
	  uart_channel_config[i].telnet_port = DEF_TELNET_PORT_START_VALUE + i;

#ifdef SET_VARIABLE_BAUD_RATE
  if (1 == baud_rate_reset)
  {
	  /* Reset to max baud rate for next channel */
	  baud_rate = 200000;
	  baud_rate_reset = 0;
  }

  baud_rate = baud_rate / 2;

  if (baud_rate < 10000)
  {
	  baud_rate = 10000;
	  baud_rate_reset = 1;
  }
#endif //SET_VARIABLE_BAUD_RATE
    }
}

/** =========================================================================
*  init_uart_channel_state
*
*  Initialize Uart channels state to default values
*
*  \param			None
*
*  \return			None
*
**/
static void init_uart_channel_state(void)
{
  int i;

  // Initialize all uart channel members to default values
  /* Assumption: UART_TX_CHAN_COUNT == UART_TX_CHAN_COUNT always */
  for (i=0;i<UART_TX_CHAN_COUNT;i++)
    {
	  {
		  /* TX initialization */
		  uart_tx_channel_state[i].channel_id = i;
		  uart_tx_channel_state[i].pending_tx_data = FALSE;
		  uart_tx_channel_state[i].read_index = 0;
		  uart_tx_channel_state[i].write_index = 0;
		  uart_tx_channel_state[i].buf_depth = 0;
		  if (i == (UART_TX_CHAN_COUNT-1))
		  {
			  /* Set last channel as currently serviced so that
			   * channel queue scan order starts from first channel */
			  uart_tx_channel_state[i].is_currently_serviced = TRUE;
		  }
		  else
		  {
			  uart_tx_channel_state[i].is_currently_serviced = FALSE;
		  }
	  }

	  {
		  /* RX initialization */
		  uart_rx_channel_state[i].channel_id = i;
		  uart_rx_channel_state[i].read_index = 0;
		  uart_rx_channel_state[i].write_index = 0;
		  uart_rx_channel_state[i].buf_depth = 0;
		  if (i == (UART_RX_CHAN_COUNT-1))
		  {
			  /* Set last channel as currently serviced so that
			   * channel queue scan order starts from first channel */
			  uart_rx_channel_state[i].is_currently_serviced = TRUE;
		  }
		  else
		  {
			  uart_rx_channel_state[i].is_currently_serviced = FALSE;
		  }
	  }
    }	//for (i=0;i<UART_TX_CHAN_COUNT;i++)
}

static void send_string_over_channel(
		char response[],
		int length,
		streaming chanend cWbSvr2AppMgr)
{
	int i;

	for (i = 0; i < length; i++)
	{
		cWbSvr2AppMgr <: response[i];
	}

	cWbSvr2AppMgr <: MARKER_END;
}

/** =========================================================================
*  validate_uart_params
*  Validates UART X parameters before applying them to UART
*
*  \param unsigned int	Uart channel identifier
*
*  \return		0 		on success
*
**/
//static int validate_uart_params(int ui_command[], char ui_cmd_response[])
static int validate_uart_params(
		int ui_command[],
		streaming chanend cWbSvr2AppMgr)
{
	int retVal = 1; //Default Success
	int i = 0;
	int j = 0;

	/*  ui_command[0] == Command type    -  ignore it for validation
	 *  ui_command[1] == UART Identifier -  < UART_RX_CHAN_COUNT
	 *  ui_command[2] == parity
	 *  ui_command[3] == stop_bits
	 *  ui_command[4] == baud
	 *  ui_command[5] == char_len
	 *  ui_command[6] == telnet_port
	 */
	for (i=1; ((i<NUM_UI_PARAMS)&& (retVal != 0)); i++)
	{
	    switch(i)
	    {
	        case 1:
	        {
				if (ui_command[1] >= UART_RX_CHAN_COUNT)
				{
					send_string_over_channel("Invalid UART Id", 16, cWbSvr2AppMgr);
					retVal = 0;
				}
				/* Break validation if command is !SET*/
				if ((ui_command[0] + 48) != CMD_CONFIG_SET)
				{
					i = NUM_UI_PARAMS; //To break looping
				}
	            break;
	        }
	        case 2:
	        {
				if ((ui_command[2] < 0) || (ui_command[2] > 4))
				{
					send_string_over_channel("Invalid Parity Config value", 28, cWbSvr2AppMgr);
					retVal = 0;
				}
	            break;
	        }
	        case 3:
	        {
				if ((ui_command[3] < 0) || (ui_command[3] > 1))
				{
					send_string_over_channel("Invalid Stop Bit value", 28, cWbSvr2AppMgr);
					retVal = 0;
				}
	            break;
	        }
	        case 4:
	        {
				if ((ui_command[4] < 150) || (ui_command[4] > UART_TX_MAX_BAUD_RATE))
				{
					send_string_over_channel("Invalid Baud Rate value", 24, cWbSvr2AppMgr);
					retVal = 0;
				}
	            break;
	        }
	        case 5:
	        {
				if ((ui_command[5] < 5) || (ui_command[5] > 9))
				{
					send_string_over_channel("Invalid UART character length", 30, cWbSvr2AppMgr);
					retVal = 0;
				}
	            break;
	        }
	        case 6:
	        {
				if ((ui_command[6] < 10) || (ui_command[6] > 65000))
				{
					send_string_over_channel("Invalid Telnet Port", 20, cWbSvr2AppMgr);
					retVal = 0;
				}
				else if (uart_channel_config[ui_command[1]].telnet_port != ui_command[6])
				{
					/* For a new telnet port, check if it is already used */
					for(j=0; j<UART_TX_CHAN_COUNT; j++)
				    {
						if (uart_channel_config[j].telnet_port == ui_command[6])
						{
							send_string_over_channel("Telnet port is already in use", 30, cWbSvr2AppMgr);
							retVal = 0;
							break;
						}
				    }
				}
				break;
	        }
	        default:
	        	break;
	    }
	}

	return retVal;
}

/** =========================================================================
*  configure_uart_channel
*  invokes MUART component api's to initialze MUART Tx and Rx threads
*
*  \param unsigned int	Uart channel identifier
*
*  \return		0 		on success
*
**/
static int configure_uart_channel(unsigned int channel_id)
{
  int chnl_config_status = ERR_CHANNEL_CONFIG;

  chnl_config_status = uart_tx_initialise_channel(
						  uart_channel_config[channel_id].channel_id,
						  uart_channel_config[channel_id].parity,
						  uart_channel_config[channel_id].stop_bits,
						  uart_channel_config[channel_id].polarity,
						  uart_channel_config[channel_id].baud,
						  uart_channel_config[channel_id].char_len);

  chnl_config_status |= uart_rx_initialise_channel(
						  uart_channel_config[channel_id].channel_id,
						  uart_channel_config[channel_id].parity,
						  uart_channel_config[channel_id].stop_bits,
						  uart_channel_config[channel_id].polarity,
						  uart_channel_config[channel_id].baud,
						  uart_channel_config[channel_id].char_len);
  return chnl_config_status;
}

/** =========================================================================
*  apply_default_uart_cfg_and_wait_for_muart_tx_rx_threads
*
*  Apply default uart channels configuration and wait for
*  MULTI_UART_GO signal from MUART_RX and MUART_RX threads
*
*  \param	chanend cTxUART		channel end sharing channel to MUART TX thrd
*
*  \param	chanend cRxUART		channel end sharing channel to MUART RX thrd
*
*  \return			None
*
**/
static void apply_default_uart_cfg_and_wait_for_muart_tx_rx_threads(
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
	int channel_id;
	int chnl_config_status = 0;
	unsigned temp;

	for (channel_id=0;channel_id<UART_TX_CHAN_COUNT;channel_id++)
	{
		chnl_config_status = configure_uart_channel(channel_id);
		if (0 != chnl_config_status)
		{
			printstr("Uart configuration failed for channel: ");
			printintln(channel_id);
			chnl_config_status = 0;
		}
		else
		{
#ifdef DEBUG_LEVEL_3
			printstr("Successful Uart configuration for channel: ");
			printintln(channel_id);
#endif //DEBUG_LEVEL_3
		}
	}

    /* Release UART rx thread */
    do { cRxUART :> temp; } while (temp != MULTI_UART_GO);
    cRxUART <: 1;

    /* Release UART tx thread */
    do {cTxUART :> temp; } while (temp != MULTI_UART_GO);
    cTxUART <: 1;

}

/** =========================================================================
*  fill_uart_channel_data
*
*  This function transmits telnet data to uart channel;
*  If uart buffer is full, data is stored in application buffer
*  Identifies uart channel for the configured telnet port

*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			None
*
**/
static void fill_uart_channel_data(
		streaming chanend cWbSvr2AppMgr)
{
	int i = 0;
	char chan_data;
	int buffer_space = 0;
	int channel_id;
	unsigned buf_depth = 0;
	int write_index = 0;

	cWbSvr2AppMgr :> channel_id;
	cWbSvr2AppMgr :> buf_depth;


	if (ERR_UART_CHANNEL_NOT_FOUND != channel_id)
	{
		for (i=0; i<buf_depth; i++)
		{
			cWbSvr2AppMgr :> chan_data;
			if (uart_tx_channel_state[channel_id].buf_depth == 0)
			{
				/* There is no pending Uart buffer data */
				/* Transmit to uart directly */
				buffer_space = uart_tx_put_char(channel_id, (unsigned int) chan_data);
				if (-1 != buffer_space)
				{
					/* Data is successfully sent to MUART TX */
					continue;
				}
			}

			if (uart_tx_channel_state[channel_id].buf_depth < TX_CHANNEL_FIFO_LEN)
		    {
				/* Uart buffer is full; fill app buffer of respective uart channel */
		    	uart_tx_channel_state[channel_id].channel_id = channel_id;
		    	write_index = uart_tx_channel_state[channel_id].write_index;
		        uart_tx_channel_state[channel_id].channel_data[write_index] = (char)chan_data;
		        write_index++;

		        if (write_index >= TX_CHANNEL_FIFO_LEN)
		        {
		        	write_index = 0;
		        }
		        uart_tx_channel_state[channel_id].write_index = write_index;
		        uart_tx_channel_state[channel_id].buf_depth++;
		    }
			else
			{
				;//Data Overflow scenario
			}
		}
	}
}


/** =========================================================================
*  receive_uart_channel_data
*
*  This function waits for channel data from MUART RX thread;
*  when uart channel data is available, decodes uart char to raw character
*  and save the data into application managed RX buffer
*
*  \param chanend cUART : channel end of data channel from MUART RX thread
*
*  \param unsigned channel_id : uart channel identifir
*
*  \return			None
*
**/
void receive_uart_channel_data(
		streaming chanend cUART,
		unsigned channel_id)
{
	unsigned uart_char, temp;
	int write_index = 0;

    /* get character over channel */
    uart_char = (unsigned)uart_rx_grab_char(channel_id);
	//cUART :> uart_char;


    /* process received value */
    temp = uart_char;

    /* validation of uart char - gives you the raw character as well */
    if (uart_rx_validate_char( channel_id, uart_char ) == 0)
    {
#ifdef DEBUG_LEVEL_3
    	printint(channel_id);
    	printstr(": ");
    	printhex(temp);
    	printstr(" -> ");
        printhexln(uart_char);
#endif	//DEBUG_LEVEL_3

        /* call api to fill uart data into application buffer */
        if (uart_rx_channel_state[channel_id].buf_depth < RX_CHANNEL_FIFO_LEN)
        {
    		/* fill client buffer of respective uart channel */
        	uart_rx_channel_state[channel_id].channel_id = channel_id;
        	write_index = uart_rx_channel_state[channel_id].write_index;
        	uart_rx_channel_state[channel_id].channel_data[write_index] =
        			uart_char;
        	//printcharln(uart_rx_channel_state[channel_id].channel_data[write_index]);
            write_index++;
            //write_index &= (RX_CHANNEL_FIFO_LEN-1);
            if (write_index >= RX_CHANNEL_FIFO_LEN)
            {
            	write_index = 0;
            }
            uart_rx_channel_state[channel_id].write_index = write_index;
            uart_rx_channel_state[channel_id].buf_depth++;
#ifdef DEBUG_LEVEL_3
            printstr("Added char to App Uart Rx buffer ");
        	printstr("write_index: ");
        	printint(write_index);
        	printstrln(" EOL");
#endif	//DEBUG_LEVEL_3
        }
#ifdef DEBUG_LEVEL_2
        else
        {
        	printstr("App uart RX buffer full. Missed char for chnl id: ");
        	printintln(channel_id);
        }
#endif	//DEBUG_LEVEL_2
    }
#ifdef DEBUG_LEVEL_1
    else
    {
        printint(channel_id);
        printstr(": ");
        printhex(temp);
        printstr(" -> ");
        printhex(uart_char);
        printstr(" [IV]\n");
    }
#endif	//DEBUG_LEVEL_1
}

/** =========================================================================
*  get_uart_channel_data
*
*  This function waits for channel data from MUART RX thread;
*  when uart channel data is available, decodes uart char to raw character
*  and save the data into application managed RX buffer
*
*  \param int channel_id : reference to uart channel identifir
*
*  \param int conn_id 	 : reference to client connection identifir
*
*  \param int read_index : reference to current buffer position to read
*  							channel data
*
*  \param int buf_depth : reference to current depth of uart channel buffer
*
*  \return			1	when there is data to send
*  					0	otherwise
*
**/
static int get_uart_channel_data(
		streaming chanend cAppMgr2WbSvr)
{
	int ret_value = 0;
	int i = 0;
	int local_read_index = 0;

	int channel_id = 0;
	int read_index = 0;
	unsigned int buf_depth = 0;
	char buffer[] = "";

	for (channel_id=0;channel_id<UART_RX_CHAN_COUNT;channel_id++)
	{
		if (TRUE == uart_rx_channel_state[channel_id].is_currently_serviced)
			break;
	}

	/* 'channel_id' now contains channel queue # that is just serviced
	 * reset it and increment to point to next channel */
	uart_rx_channel_state[channel_id].is_currently_serviced = FALSE;
	channel_id++;
	//channel_id &= (UART_RX_CHAN_COUNT-1);
    if (channel_id >= UART_RX_CHAN_COUNT)
    {
    	channel_id = 0;
    }
	uart_rx_channel_state[channel_id].is_currently_serviced = TRUE;

	read_index = uart_rx_channel_state[channel_id].read_index;
	buf_depth = uart_rx_channel_state[channel_id].buf_depth;

	//printint(buf_depth); TODO: Bug: Data for chnl 7 is always present
	if ((buf_depth > 0) && (buf_depth <= RX_CHANNEL_FIFO_LEN))
	{
		/* Send Uart Id and buffer depth */
		cAppMgr2WbSvr <: UART_DATA_FROM_UART_TO_APP;
		cAppMgr2WbSvr <: channel_id;
		cAppMgr2WbSvr <: buf_depth;

		local_read_index = read_index;

		for (i=0; i<buf_depth; i++)
		{
			/* Send Uart X data over channel */
			cAppMgr2WbSvr <: uart_rx_channel_state[channel_id].channel_data[local_read_index];
			local_read_index++;
			if (local_read_index >= RX_CHANNEL_FIFO_LEN)
			{
				local_read_index = 0;
			}
		}

		/* Data is pushed to app manager thread; Update buffer state pointers */
		read_index += buf_depth;
		if (read_index > (RX_CHANNEL_FIFO_LEN-1))
		{
			read_index -= RX_CHANNEL_FIFO_LEN;
		}
		uart_rx_channel_state[channel_id].read_index = read_index;
		uart_rx_channel_state[channel_id].buf_depth -= buf_depth; //= 0;

		ret_value = 1;
	}

	return ret_value;
}

/** =========================================================================
*  fill_uart_channel_data_from_queue
*
*  This function primarily handles UART TX buffer overflow condition by
*  storing data into its application buffer when UART Tx buffer is full
*  This function reads data from uart channel specific application TX buffer
*  and invokes MUART TX api to send to uart channel of MUART TX component
*
*  \param 			None
*
*  \return			None
*
**/
void fill_uart_channel_data_from_queue()
{
	int channel_id;
	int buffer_space = 0;
	char data;
	int read_index = 0;

	for (channel_id=0;channel_id<UART_TX_CHAN_COUNT;channel_id++)
	{
		if (TRUE == uart_tx_channel_state[channel_id].is_currently_serviced)
			break;
	}

	/* 'channel_id' now contains channel queue # that is just serviced
	 * reset it and increment to point to next channel */
	uart_tx_channel_state[channel_id].is_currently_serviced = FALSE;
	channel_id++;
	//channel_id &= (UART_TX_CHAN_COUNT-1);
    if (channel_id >= UART_TX_CHAN_COUNT)
    {
    	channel_id = 0;
    }
	uart_tx_channel_state[channel_id].is_currently_serviced = TRUE;

	if ((uart_tx_channel_state[channel_id].buf_depth > 0) &&
		(uart_tx_channel_state[channel_id].buf_depth <= TX_CHANNEL_FIFO_LEN))
	{
		read_index = uart_tx_channel_state[channel_id].read_index;
		data = uart_tx_channel_state[channel_id].channel_data[read_index];
		/* There is pending Uart buffer data */
		/* Try to transmit to uart directly */
		buffer_space = uart_tx_put_char(channel_id, (unsigned int)data);
		if (-1 != buffer_space)
		{
			/* Data is pushed to uart successfully */
			read_index++;
	        //read_index &= (TX_CHANNEL_FIFO_LEN-1);
			if (read_index >= TX_CHANNEL_FIFO_LEN)
			{
				read_index = 0;
			}
	        uart_tx_channel_state[channel_id].read_index = read_index;
	        uart_tx_channel_state[channel_id].buf_depth--;
#ifdef DEBUG_LEVEL_3
	        printstr("Added char to uart App TX buffer for chnk id: ");
	        printintln(channel_id);
#endif //DEBUG_LEVEL_3
		}
	}
}

/** =========================================================================
*  re_apply_uart_channel_config
*
*  This function either configures or reconfigures a uart channel
*
*  \param	s_uart_channel_config sUartChannelConfig Reference to UART conf
*
*  \param	chanend cTxUART		channel end sharing channel to MUART TX thrd
*
*  \param	chanend cRxUART		channel end sharing channel to MUART RX thrd
*
*  \return			None
*
**/
#pragma unsafe arrays
static int re_apply_uart_channel_config(
		int channel_id,
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
	int ret_val = 0;
    int chnl_config_status = 0;
    timer t;

    /* Reconfigure Uart channel request */
    uart_tx_reconf_pause( cTxUART, t );
    uart_rx_reconf_pause( cRxUART );

    chnl_config_status = configure_uart_channel(channel_id);

    uart_tx_reconf_enable( cTxUART );
    uart_rx_reconf_enable( cRxUART );

    if (0 != chnl_config_status)
    {
    	printint(channel_id);
    	printstrln(": Channel reconfig failed");
    }
	//TODO: Send response back on the channel
}

/** =========================================================================
*  parse_uart_command_data
*
*  This function parses UI command data to identify different UART params
*
*  \param	chanend cWbSvr2AppMgr channel end sharing web server thread
*
*  \return			None
*
**/
static int parse_uart_command_data(
		streaming chanend cWbSvr2AppMgr,
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
	char ui_cmd_unparsed[UI_COMMAND_LENGTH];
	char ui_cmd_response[UI_COMMAND_LENGTH]; //TODO; Chk if this can be optimized
	int ui_command[NUM_UI_PARAMS];
	int cmd_length = 0;
    char cmd_type;

	int i, j;
	int iTemp = 0;
    char dv[20]; //
    int index_start = 0;
    int index_end = 0;
    int index_cfg = -1;
    int index_uart = 0;
    char ui_param[20];

    /* Get UART command data */
    {
        int done = 0;
        int i = 0;

        do
        {
            cWbSvr2AppMgr :> ui_cmd_unparsed[i];
            if(ui_cmd_unparsed[i] == MARKER_END)
            {
                done = 1;
            }
            else
            {
                i++;
            }
        } while(done == 0);

        cmd_length = i;
    }

    // Get the variables
    for (i = 0; i < cmd_length; i++)
    {
        if (ui_cmd_unparsed[i] == MARKER_START)
        {
            if (index_end == 0)
            {
                index_cfg++;
                index_end = i + 1;
                index_start = i + 1;
            } // if(index_end == 0)
            else
            {
                // clear
            	ui_cmd_unparsed[index_cfg] = 0;

            	/* Clear the array */
                for (iTemp = 0; iTemp < 20; iTemp++)
                {
                	dv[iTemp] = '\0';
                }

                for (j = 0; j < (i - index_start); j++)
                {
                    dv[j] = ui_cmd_unparsed[j + index_start];
                }

                ui_command[index_cfg] = atoi(dv);
                index_end = 0;
                index_start = 0;
            } //else [if (index_end == 0)]
        } //if (ui_cmd_unparsed[i] == '~')
    } //for (i = 0; i < cmd_length; i++)

    // Now process the Command request
    //if (validate_uart_params(ui_command, ui_cmd_response) //TODO
    if (validate_uart_params(ui_command, cWbSvr2AppMgr))
    {
        cmd_type = ui_command[0] + 48; // +48 for char
        index_uart = ui_command[1]; //UART channel identifier

        if (CMD_CONFIG_GET == cmd_type)
        {
            // Get settings and store it in config_structure array
            // config_structure = s_uart_channel_config.abc
        	ui_command[2] = uart_channel_config[index_uart].parity;
        	ui_command[3] = uart_channel_config[index_uart].stop_bits;
        	ui_command[4] = uart_channel_config[index_uart].baud;
        	ui_command[5] = uart_channel_config[index_uart].char_len;
        	//Parameter 'Polarity' is not yet part of UI
        	ui_command[6] = uart_channel_config[index_uart].telnet_port;
        }
        else if (CMD_CONFIG_SET == cmd_type)
        {
            // Set configuration from the data available in config_structure
            uart_channel_config[index_uart].channel_id  = ui_command[1];
            uart_channel_config[index_uart].parity      = ui_command[2];
            uart_channel_config[index_uart].stop_bits   = ui_command[3];
            uart_channel_config[index_uart].baud        = ui_command[4];
            uart_channel_config[index_uart].char_len    = ui_command[5];
            uart_channel_config[index_uart].telnet_port = ui_command[6];

            //re_apply_uart_channel_config(uart_channel_config[index_uart], cTxUART, cRxUART);
            re_apply_uart_channel_config(index_uart, cTxUART, cRxUART);
            //TODO: Channel backup may be required and need to be reconfigured upon failure
            //pending_cmd_to_send.flag = 1;
            //pending_cmd_to_send.cmd_type = ui_command[0];
            pending_cmd_to_send.uart_id = ui_command[1]; //UART Id
        }

    	/* Form response and send it back to channel */
        for (i = 0; i < NUM_UI_PARAMS; i++)
        {
            j = 0;
            cWbSvr2AppMgr <: MARKER_START;
            if (0 != ui_command[i])
            {
                while(0 != ui_command[i])
                {
        			ui_param[j] = ui_command[i]%10;
                    ui_command[i] = ui_command[i]/10;
                    j++;
                }
                while(0 != j)
                {
                    cWbSvr2AppMgr <: (char)(ui_param[j-1] + 48);
                    j--;
                }
            }
            else
            {
                cWbSvr2AppMgr <: (char)(ui_command[i] + 48);
            }
            cWbSvr2AppMgr <: MARKER_START;
        }
        cWbSvr2AppMgr <: MARKER_END;
    }

    //TODO: Incase of error in applying UART parameters, error msg to be sent

}

/** 
 *  The multi uart manager thread. This thread
 *  (i) periodically polls for data on application Tx buffer, in order to transmit to telnet clients
 *  (ii) waits for channel data from MUART Rx thread
 *
 *  \param	chanend cWbSvr2AppMgr channel end sharing web server thread
 *  \param	chanend cTxUART		channel end sharing channel to MUART TX thrd
 *  \param	chanend cRxUART		channel end sharing channel to MUART RX thrd
 *  \return	None
 *
 */
void app_manager_handle_uart_data(
		streaming chanend cWbSvr2AppMgr,
		streaming chanend cAppMgr2WbSvr,
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
	timer txTimer, rxTimer;
	unsigned txTimeStamp, rxTimeStamp;
	char rx_channel_id;
	unsigned int local_port = 0;
	int conn_id  = 0;
	int WbSvr2AppMgr_chnl_data = 9999;
	char flash_config_valid;
	int i, j, intdata;
	char flash_data;

	//TODO: Flash cold start should happen here
	/* Applying default in-program values, in case Cold start fails */
	uart_channel_init();

	for(i = 0; i < UART_TX_CHAN_COUNT; i++)
    {
    	/* Send uart key data to app server */
    	cWbSvr2AppMgr <: uart_channel_config[i].channel_id;
    }

	init_uart_channel_state();

	apply_default_uart_cfg_and_wait_for_muart_tx_rx_threads(
			cTxUART,
			cRxUART);

	txTimer :> txTimeStamp;
	txTimeStamp += MGR_TX_TMR_EVENT_INTERVAL;

	rxTimer :> rxTimeStamp;
	rxTimeStamp += MGR_RX_TMR_EVENT_INTERVAL;

	// Loop forever processing Tx and Rx channel data
	while(1)
    {
      select
        {
#pragma ordered
#pragma xta endpoint "ep_1"
		  case cRxUART :> rx_channel_id:
    		  //Read data from MUART RX thread
    		  //receive_uart_channel_data(cRxUART, (unsigned)rx_channel_id);
    		  receive_uart_channel_data(cRxUART, rx_channel_id);
			  break;
    	  case txTimer when timerafter (txTimeStamp) :> void :
    		  //Read data from App TX queue
    		  fill_uart_channel_data_from_queue();
			  txTimeStamp += MGR_TX_TMR_EVENT_INTERVAL;
			  break;
    	  case rxTimer when timerafter (rxTimeStamp) :> void :
    		  //Send data from App RX queue
    		  get_uart_channel_data(cAppMgr2WbSvr);
			  rxTimeStamp += MGR_RX_TMR_EVENT_INTERVAL;
			  break;
    	  case cWbSvr2AppMgr :> WbSvr2AppMgr_chnl_data :
    		  if (UART_CMD_FROM_APP_TO_UART == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* This is a UART command. Parse to get command type
    			   * and process accordingly */
    			  parse_uart_command_data(cWbSvr2AppMgr, cTxUART, cRxUART);
    		  }
    		  else if (UART_SET_END_FROM_APP_TO_UART == WbSvr2AppMgr_chnl_data)
    		  {
    			  //if (pending_cmd_to_send.flag)
    			  {
    				  cWbSvr2AppMgr <: UART_CMD_MODIFY_TLNT_PORT_FROM_UART_TO_APP;
    				  //cWbSvr2AppMgr <: cmd_type;
    				  cWbSvr2AppMgr <: pending_cmd_to_send.uart_id;
    				  cWbSvr2AppMgr <: uart_channel_config[pending_cmd_to_send.uart_id].telnet_port;
    				  //pending_cmd_to_send.flag = 0;
    			  }
    		  }
    		  else if (UART_RESTORE_END_FROM_APP_TO_UART == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* Send all telnet port numbers to App server */
				  cWbSvr2AppMgr <: UART_CMD_MODIFY_ALL_TLNT_PORTS_FROM_UART_TO_APP;
					for(i = 0; i < UART_TX_CHAN_COUNT; i++)
				    {
				    	/* Send uart key data to app server */
				    	cWbSvr2AppMgr <: uart_channel_config[i].channel_id;
				    	cWbSvr2AppMgr <: uart_channel_config[i].telnet_port;
				    }
    		  }
    		  else if (UART_DATA_FROM_APP_TO_UART == WbSvr2AppMgr_chnl_data)
    		  {
    			  fill_uart_channel_data(cWbSvr2AppMgr);
    		  }
    		  break;
        }
    }
}

//#pragma xta command "analyze function receive_uart_channel_data"
