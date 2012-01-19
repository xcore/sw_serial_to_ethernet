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
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
#define STR_N_CPY(dest, src, len) do { dest[len-1] = src[len-1]; \
                                        len--; \
                                      } while (0!=len)
#define DEF_TELNET_PORT_START_VALUE		46
#define	MAX_BIT_RATE					115200		//bits per sec
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
void uart_channel_init(void)
{
  int i;

  for (i=0;i<UART_TX_CHAN_COUNT;i++)
    {
	  // Initialize Uart channels configuration data structure
	  uart_channel_config[i].channel_id = 0;
	  uart_channel_config[i].parity = none;
	  uart_channel_config[i].stop_bits = sb_1;
	  uart_channel_config[i].baud = MAX_BIT_RATE;
	  uart_channel_config[i].char_len = DEF_CHAR_LEN;
	  uart_channel_config[i].polarity = start_0;
	  uart_channel_config[i].telnet_port = DEF_TELNET_PORT_START_VALUE + i;
	  //conn_id is available only during active telnet session establishment
	  uart_channel_config[i].conn_id = 0;
	  uart_channel_config[i].is_configured = FALSE;
	  uart_channel_config[i].is_active = FALSE;
    }
}

/** =========================================================================
*  init_uart_channel_state
*
*  Initialize Uart channels state to default values
*
*  \param
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
		  uart_tx_channel_state[i].channel_id = 0;
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
		  uart_rx_channel_state[i].channel_id = 0;
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
*  valid_telnet_port
*
*  checks whether port_num is a valid and configured telnet port

*  \param unsigned int	telnet port number
*
*  \return		1 		on success
*
**/
int valid_telnet_port(unsigned int port_num)
{
	int i;

	/* Look up for configured telnet ports */
	for (i=0;i<UART_TX_CHAN_COUNT;i++)
	{
		if ((uart_channel_config[i].telnet_port == port_num) &&
			(uart_channel_config[i].is_configured == TRUE))
			return 1;
	}

	return 0;
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
int configure_uart_channel(unsigned int channel_id)
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
*  update_uart_channel_config_conn_id
*
*  Identifies active telnet client connection id and maps it to corresponding
*  uart channel's config structure

*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			1
*
**/
int update_uart_channel_config_conn_id(
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
			if (FALSE == uart_channel_config[i].is_active)
			{
				uart_channel_config[i].conn_id = conn_id;
				uart_channel_config[i].is_active = TRUE;
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

	channel_id = get_uart_channel_id(conn.local_port, conn.id);

	if (ERR_UART_CHANNEL_NOT_FOUND != channel_id)
	{
		if (uart_tx_channel_state[channel_id].buf_depth == 0)
		{
			/* There is no pending Uart buffer data */
			/* Transmit to uart directly */
			buffer_space = uart_tx_put_char(channel_id, (unsigned int)data);

			if (buffer_space < UART_TX_BUF_SIZE)
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

/** =========================================================================
*  receive_uart_channel_data
*
*  This function waits for channel data from MUART RX thread;
*  when uart channel data is available, decodes uart char to raw character
*  and save the data into application managed RX buffer
*
*  \param chanend cUART : channel end of data channel from MUART RX thread
*
*  \param int channel_id : uart channel identifir
*
*  \return			None
*
**/
static void receive_uart_channel_data(
		streaming chanend cUART,
		int channel_id)
{
	unsigned uart_char, temp;
	//int channel_id;
	int write_index = 0;

    /* get character over channel */
    //cUART :>  channel_id;
    cUART :> uart_char;

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

	if ((buf_depth > 0) && (buf_depth <= RX_CHANNEL_FIFO_LEN))
	{
		/* Store client connection id pertaining to this uart channel */
		conn_id = uart_channel_config[channel_id].conn_id;
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
		printintln(uart_channel_config[channel_id].is_active);
#endif	//DEBUG_LEVEL_3
		ret_value = 1;
	}
#ifdef DEBUG_LEVEL_1
	else
	{
		printstr("RX App Buffer full for ChnlId-");
		printint(channel_id);
		printstr("conn_id-");
		printint(conn_id);
		printstr("isActive?-");
		printintln(uart_channel_config[channel_id].is_active);
	}
#endif	//DEBUG_LEVEL_1

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
		if (buffer_space < UART_TX_BUF_SIZE)
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

/* The multi-uart application manager thread to handle uart
 * data communication to web server clients */
/** =========================================================================
*  app_manager_handle_uart_data
*
*  The multi uart manager thread. This thread
*  (i) periodically polls for data on application Tx buffer, in order to
*  transmit to telnet clients
*  (ii) waits for channel data from MUART Rx thread
*
*  \param	chanend cTxUART		channel end sharing channel to MUART TX thread
*
*  \param	chanend cRxUART		channel end sharing channel to MUART RX thread
*
*  \return	None
*
**/
void app_manager_handle_uart_data(
		streaming chanend cTxUART,
		streaming chanend cRxUART)
{
	timer txTimer;
	unsigned txTimeStamp;
	int channel_id;

	init_uart_channel_state();

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
			  txTimeStamp += 1000;
			  break ;
    	  case cRxUART :> channel_id :
    		  //Read data from MUART RX thread
    		  receive_uart_channel_data(cRxUART, channel_id);
			  break ;
    	  default:
    		  break;
        }
    }
}
