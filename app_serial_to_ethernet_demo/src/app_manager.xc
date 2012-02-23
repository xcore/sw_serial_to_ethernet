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
#include "telnetd.h"
#include "app_manager.h"
#include "user_client.h"
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
#define STR_N_CPY(dest, src, len) do { dest[len-1] = src[len-1]; \
                                        len--; \
                                      } while (0!=len)
#define DEF_TELNET_PORT_START_VALUE		46
#define	MAX_BIT_RATE					115200 //100000		//bits per sec
#define TIMER_FREQUENCY					100000000	//100 Mhz
/* Default length of a uart character in bits */
#define	DEF_CHAR_LEN					8
#define MGR_TX_TMR_EVENT_INTERVAL		(TIMER_FREQUENCY /	\
										(MAX_BIT_RATE * UART_TX_CHAN_COUNT))
/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
s_uart_channel_config	uart_channel_config[UART_TX_CHAN_COUNT];
s_uart_tx_channel_fifo	uart_tx_channel_state[UART_TX_CHAN_COUNT];
s_uart_rx_channel_fifo	uart_rx_channel_state[UART_RX_CHAN_COUNT];
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
	  //conn_id is available only during active telnet session establishment
	  uart_channel_config[i].telnet_conn_id = 0;
	  uart_channel_config[i].is_configured = FALSE;
	  uart_channel_config[i].is_telnet_active = FALSE;

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
			/* Successfully configured uart channel */
			uart_channel_config[channel_id].is_configured = TRUE;
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
*  add_telnet_conn_id_for_uart_channel
*
*  Updates tcp client connection id to configured telnet port
*   Note: we wont have uart channel id info at this event
*
*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			1
*
**/
static int add_telnet_conn_id_for_uart_channel(
		unsigned int telnet_port,
		int conn_id)
{
	int i;

	for (i=0;i<UART_TX_CHAN_COUNT;i++)
	{
		if ((uart_channel_config[i].telnet_port == telnet_port) &&
			(uart_channel_config[i].is_configured == TRUE))
		{
			/* As telnet connection id is not available during
			 * uart channel config, it is updated only when active telnet
			 * connection is established */
			if (FALSE == uart_channel_config[i].is_telnet_active)
			{
				uart_channel_config[i].telnet_conn_id = conn_id;
				uart_channel_config[i].is_telnet_active = TRUE;
#ifdef DEBUG_LEVEL_3
				printstr("App_manager-");printintln(conn_id);
#endif	//DEBUG_LEVEL_3
			}
		}
	}
	return 1;
}

/** =========================================================================
*  get_uart_channel_id
*
*  Identifies uart channel for the configured telnet port

*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			uart channel id on successfull match
*  					ERR_UART_CHANNEL_NOT_FOUND, if uart channel is not found
*
**/
static unsigned int get_uart_channel_id(
		unsigned int telnet_port,
		int conn_id)
{
	int i;
	int channel_id = ERR_UART_CHANNEL_NOT_FOUND;

	// Initialize all channel members to default values
	for (i=0;i<UART_TX_CHAN_COUNT;i++)
	{
		if ((uart_channel_config[i].telnet_port == telnet_port) &&
			(uart_channel_config[i].is_configured == TRUE))
		{
			return uart_channel_config[i].channel_id;
		}
	}

	return channel_id;
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
void fill_uart_channel_data(
		xtcp_connection_t &conn,
		char data)
{
	int buffer_space = 0;
	int channel_id;
	int write_index = 0;

	if (TELNET_PORT_USER_CMDS == conn.local_port)
	{
		parse_client_usr_command(data);
	}
	else
	{
		channel_id = get_uart_channel_id(conn.local_port, conn.id);

		if (ERR_UART_CHANNEL_NOT_FOUND != channel_id)
		{
			if (uart_tx_channel_state[channel_id].buf_depth == 0)
			{
				/* There is no pending Uart buffer data */
				/* Transmit to uart directly */
				buffer_space = uart_tx_put_char(channel_id, (unsigned int)data);

				if (-1 != buffer_space)
				{
					/* Data is successfully sent to MUART TX */
					return;
				}
			}

		    if (uart_tx_channel_state[channel_id].buf_depth < TX_CHANNEL_FIFO_LEN)
		    {
				/* Uart buffer is full; fill app buffer of respective uart channel */
		    	uart_tx_channel_state[channel_id].channel_id = channel_id;
		    	write_index = uart_tx_channel_state[channel_id].write_index;
		        uart_tx_channel_state[channel_id].channel_data[write_index] = data;
		        write_index++;
		        //write_index &= (TX_CHANNEL_FIFO_LEN-1);
		        if (write_index >= TX_CHANNEL_FIFO_LEN)
		        {
		        	write_index = 0;
		        }
		        uart_tx_channel_state[channel_id].write_index = write_index;
		        uart_tx_channel_state[channel_id].buf_depth++;
#ifdef DEBUG_LEVEL_3
		        printstr("Added to TX buffer; buf_depth is: ");
		        printintln(uart_tx_channel_state[channel_id].buf_depth);
#endif	//DEBUG_LEVEL_3
		    }
#ifdef DEBUG_LEVEL_1
		    else if (uart_tx_channel_state[channel_id].buf_depth >= TX_CHANNEL_FIFO_LEN)
		    {
		    	printstr("Uart App TX buffer full...[data is dropped]. Chnl id: ");
		        printintln(channel_id);
		    }
#endif	//DEBUG_LEVEL_1
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
int get_uart_channel_data(
		int &channel_id,
		int &conn_id,
		int &read_index,
		unsigned int &buf_depth,
		char buffer[])
{
	int ret_value = 0;
	int i = 0;
	int local_buf_depth = 0;
	int local_read_index = 0;

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
		/* Store client connection id pertaining to this uart channel */
		conn_id = uart_channel_config[channel_id].telnet_conn_id;
		local_read_index = read_index;
		local_buf_depth = buf_depth;

		i = 0;
		while (0 != local_buf_depth)
		{
			buffer[i] =
			 uart_rx_channel_state[channel_id].channel_data[local_read_index];
			i++;
			local_read_index++;
			//local_read_index &= (RX_CHANNEL_FIFO_LEN-1);
			if (local_read_index >= RX_CHANNEL_FIFO_LEN)
			{
				local_read_index = 0;
			}
			local_buf_depth--;
		}

#ifdef DEBUG_LEVEL_3
		printstr("ChnlId-");
		printint(channel_id);
		printstr("conn_id-");
		printint(conn_id);
		printstr("isActive?-");
		printintln(uart_channel_config[channel_id].is_telnet_active);
#endif	//DEBUG_LEVEL_3
		ret_value = 1;
	}

	return ret_value;
}

/** =========================================================================
*  update_uart_rx_channel_state
*
*  This function waits for channel data from MUART RX thread;
*  when uart channel data is available, decodes uart char to raw character
*  and save the data into application managed RX buffer
*
*  \param int channel_id : reference to uart channel identifir
*
*  \param int read_index : reference to current buffer position to read
*  							channel data
*
*  \param int buf_depth : reference to current depth of uart channel buffer
*
*  \return			None
*
**/
void update_uart_rx_channel_state(
		int &channel_id,
		int &read_index,
		unsigned int &buf_depth)
{
#ifdef DEBUG_LEVEL_3
	printstr("Values of Uart ChnlId  - Read index - Buffer depth: ");
	printint(channel_id);
	printint(read_index);
	printintln(buf_depth);
#endif	//DEBUG_LEVEL_3

	/* Data is sent to client successfully */
	read_index += buf_depth;
	if (read_index > (RX_CHANNEL_FIFO_LEN-1))
	{
		read_index -= RX_CHANNEL_FIFO_LEN;
	}
	uart_rx_channel_state[channel_id].read_index = read_index;
	uart_rx_channel_state[channel_id].buf_depth -= buf_depth; //= 0;
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
#ifdef SIMULATION
		/* Manually force a value MUART Tx thread consumes the data */
		buffer_space = 0;
#endif
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
*  A crude way to determing whether it is config or reconfig is to check
*  for valid values of prev_telnet_conn_id and prev_telnet_port; if yes,
*  then it is a reconfig request
*
*  \param	chanend cWbSvr2AppMgr channel end sharing web server thread
*
*  \param	chanend cTxUART		channel end sharing channel to MUART TX thrd
*
*  \param	chanend cRxUART		channel end sharing channel to MUART RX thrd
*
*  \return			None
*
**/
static void re_apply_uart_channel_config(
		streaming chanend cWbSvr2AppMgr,
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
    int channel_id = 0;
    int prev_telnet_conn_id = 0;
    int prev_telnet_port = 0;
    int chnl_config_status = 0;
    timer t;

	//Read uart reconfig details from web server thread
    /* Other config params are already stored in global structure */
    cWbSvr2AppMgr :> channel_id;
    cWbSvr2AppMgr :> prev_telnet_conn_id;
    cWbSvr2AppMgr :> prev_telnet_port;

    if (1) //TODO: to add a valid condition check here
	{
		/* Reconfigure Uart channel request */
        uart_tx_reconf_pause( cTxUART, t );
        uart_rx_reconf_pause( cRxUART );

	    chnl_config_status = configure_uart_channel(channel_id);
	    if (0 == chnl_config_status)
	    {
	    	if (0 == prev_telnet_conn_id)
	    	{
	    		cWbSvr2AppMgr <: SET_NEW_TELNET_SESSION;
	    	}
	    	else
	    	{
	    		/* Close this active telnet client session and establish a
	    		 *  new session on new telnet port */
	    		cWbSvr2AppMgr <: RESET_TELNET_SESSION;
	    	}
	    	/* Send new telnet port */
	    	cWbSvr2AppMgr <: uart_channel_config[channel_id].telnet_port;
	    }
	    else
	    {
	    	printint(channel_id);
	    	printstrln(": Channel reconfig failed");
	    }

        uart_tx_reconf_enable( cTxUART );
        uart_rx_reconf_enable( cRxUART );
	}
    else
    {
		/* Signal the end of current transaction */
		cWbSvr2AppMgr <: CHNL_TRAN_END;
    }
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
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
	timer txTimer;
	unsigned txTimeStamp;
	char rx_channel_id;
	unsigned int local_port = 0;
	int conn_id  = 0;
	int WbSvr2AppMgr_chnl_data = 9999;


	/* Initiate uart channel configuration with default values */
	uart_channel_init();
	init_uart_channel_state();

	apply_default_uart_cfg_and_wait_for_muart_tx_rx_threads(
			cTxUART,
			cRxUART);

	txTimer :> txTimeStamp;
	txTimeStamp += MGR_TX_TMR_EVENT_INTERVAL;

	// Loop forever processing Tx and Rx channel data
	while(1)
    {
      select
        {
    	  case txTimer when timerafter (txTimeStamp) :> void :
    		  //Read data from App TX queue
    		  fill_uart_channel_data_from_queue();
			  //txTimeStamp += MGR_TX_TMR_EVENT_INTERVAL;
			  txTimeStamp += 4000;
			  break ;
    	  case cWbSvr2AppMgr :> WbSvr2AppMgr_chnl_data :
    		  if (RECONF_UART_CHANNEL == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* Update uart channels with new uart config */
    			  re_apply_uart_channel_config(
    					  cWbSvr2AppMgr,
    					  cTxUART,
    					  cRxUART);
    		  }
    		  else if (ADD_TELNET_CONN_ID == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* There is a telnet client connection.
    			   * Update local connection state */
    			  cWbSvr2AppMgr :> local_port;
    			  cWbSvr2AppMgr :> conn_id;
    			  add_telnet_conn_id_for_uart_channel(local_port, conn_id);
    		  }
			  break ;
#pragma xta endpoint "ep_1"
		  case cRxUART :> rx_channel_id:
    		  //Read data from MUART RX thread
    		  //receive_uart_channel_data(cRxUART, (unsigned)rx_channel_id);
    		  receive_uart_channel_data(cRxUART, rx_channel_id);
			  break ;
        }
    }
}

//#pragma xta command "analyze function receive_uart_channel_data"
