// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename:
Project :
Author  :
Version :
Purpose
-----------------------------------------------------------------------------


===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include <xs1.h>
#include <platform.h>
#include "httpd.h"
#include "web_server.h"
#include "telnetd.h"
#include "xtcp_buffered_client.h"

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
#define	DEF_CHAR_LEN					8			//Length of a character in bits
#define MGR_TX_TMR_EVENT_INTERVAL		(TIMER_FREQUENCY / (MAX_BIT_RATE * UART_TX_CHAN_COUNT))

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
*  description: Initialize Uart channels data structure
*
*  \param
*
*  \return			None
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
	  uart_channel_config[i].conn_id = 0; //This is available only during active telnet session establishment
	  uart_channel_config[i].is_configured = FALSE;
	  uart_channel_config[i].is_active = FALSE;
    }
}

/** =========================================================================
*  init_uart_channel_state
*
*  description: Set Uart channels state to default init values
*
*  \param
*
*  \return			None
*
**/
static void init_uart_channel_state(void)
{
  int i;

  for (i=0;i<UART_TX_CHAN_COUNT;i++)
    {
	  {
		  // Initialize all uart channel members to default values
		  uart_tx_channel_state[i].channel_id = 0;
		  uart_tx_channel_state[i].pending_tx_data = FALSE;
		  uart_tx_channel_state[i].read_index = 0;
		  uart_tx_channel_state[i].write_index = 0;
		  uart_tx_channel_state[i].buf_depth = 0;
		  if (i == (UART_TX_CHAN_COUNT-1))
		  {
			  /* Set last channel as currently serviced so that channel queue
			   * scan order starts from first channel */
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
			  /* Set last channel as currently serviced so that channel queue
			   * scan order starts from first channel */
			  uart_rx_channel_state[i].is_currently_serviced = TRUE;
		  }
		  else
		  {
			  uart_rx_channel_state[i].is_currently_serviced = FALSE;
		  }
	  }
    }
}

/** =========================================================================
*  valid_telnet_port
*  description: checks whether port_num is valid and configured telnet port

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
*  description: invokes MUART component api's to initialze MUART Tx and Rx
*    threads

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
*  description: invokes MUART component api's to initialze MUART Tx and Rx
*    threads

*  \param unsigned int    Uart channel identifier
*
*  \return			None
*
**/
int update_uart_channel_config_conn_id(unsigned int telnet_port, int conn_id)
{
	int i;

	for (i=0;i<UART_TX_CHAN_COUNT;i++)
	{
		if ((uart_channel_config[i].telnet_port == telnet_port) &&
			(uart_channel_config[i].is_configured == TRUE))
		{
			/* As telnet connection id is not available during uart channel config,
			 * it is updated only when active telnet connection is established */
			if (FALSE == uart_channel_config[i].is_active)
			{
				uart_channel_config[i].conn_id = conn_id;
				uart_channel_config[i].is_active = TRUE;
#ifdef DEBUG_LEVEL_3
				printstr("app_manager-");printint(conn_id);printstr("<>");
#endif	//DEBUG_LEVEL_3
			}
		}
	}
	return 1;
}

static unsigned int get_uart_channel_id(unsigned int telnet_port, int conn_id)
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

void fill_uart_channel_data(xtcp_connection_t &conn,
                            char data)
{
	int buffer_space = 0;
	int channel_id;
	int write_index = 0;

	channel_id = get_uart_channel_id(conn.local_port, conn.id);

	if (uart_tx_channel_state[channel_id].buf_depth == 0)
	{
		/* There is no pending Uart buffer data */
		/* Transmit to uart directly */
		buffer_space = uart_tx_put_char(channel_id, (unsigned int)data);

		if (buffer_space < UART_TX_BUF_SIZE)
		{
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
        printstr("Added to TX buffer; buf_depth is: "); printintln(uart_tx_channel_state[channel_id].buf_depth);
#endif	//DEBUG_LEVEL_3
    }
#ifdef DEBUG_LEVEL_1
    else if (uart_tx_channel_state[channel_id].buf_depth >= TX_CHANNEL_FIFO_LEN)
    {
    	printstrln("Uart TX buffers are full...[data is dropped]");
    }
#endif	//DEBUG_LEVEL_1
}

static void receive_uart_channel_data(streaming chanend cUART, int channel_id)
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
    	printint(channel_id); printstr(": "); printhex(temp); printstr(" -> ");
        printhexln(uart_char);
#endif	//DEBUG_LEVEL_3

        //printstr("C Id: ");printintln(channel_id);
        /* call api to fill uart data into client */
        if (uart_rx_channel_state[channel_id].buf_depth < RX_CHANNEL_FIFO_LEN)
        {
    		/* fill client buffer of respective uart channel */
        	uart_rx_channel_state[channel_id].channel_id = channel_id;
        	write_index = uart_rx_channel_state[channel_id].write_index;
        	uart_rx_channel_state[channel_id].channel_data[write_index] = uart_char;
            write_index++;
            //write_index &= (RX_CHANNEL_FIFO_LEN-1);
            if (write_index >= RX_CHANNEL_FIFO_LEN)
            {
            	write_index = 0;
            }
            uart_rx_channel_state[channel_id].write_index = write_index;
            uart_rx_channel_state[channel_id].buf_depth++;
#ifdef DEBUG_LEVEL_3
        	printstr("write_index: "); printint(write_index); printstrln(" EOL");
            printstrln("Added char to App Uart Rx buffer");
#endif	//DEBUG_LEVEL_3
        }
        else
        {
#ifdef DEBUG_LEVEL_2
        	printstrln("App Uart RX Buffer full...Missed to add char");
#endif	//DEBUG_LEVEL_2

        }
    }
    else
    {
#ifdef DEBUG_LEVEL_1
        printint(channel_id); printstr(": "); printhex(temp); printstr(" -> ");
        printhex(uart_char);
        printstr(" [IV]\n");
#endif	//DEBUG_LEVEL_1
    }
}

int get_uart_channel_data(int &channel_id, int &conn_id, int &read_index, unsigned int &buf_depth, char buffer[])
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
		/* Return client connection id pertaining to this uart channel */
		conn_id = uart_channel_config[channel_id].conn_id;
		local_read_index = read_index;
		local_buf_depth = buf_depth;

		i = 0;
		while (0 != local_buf_depth)
		{
			buffer[i] = uart_rx_channel_state[channel_id].channel_data[local_read_index];
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
		printstr("ChnlId-");printint(channel_id);printstr("conn_id-");printint(conn_id);printstr("isActive?-");printintln(uart_channel_config[channel_id].is_active);
#endif	//DEBUG_LEVEL_3
		ret_value = 1;
	}
#ifdef DEBUG_LEVEL_1
	else
	{
		printstr("RX App Buffer full for ChnlId-");printint(channel_id);printstr("conn_id-");printint(conn_id);printstr("isActive?-");printintln(uart_channel_config[channel_id].is_active);
	}
#endif	//DEBUG_LEVEL_1

	return ret_value;
}

void update_uart_rx_channel_state(int &channel_id, int &read_index, unsigned int &buf_depth)
{
#ifdef DEBUG_LEVEL_3
	printint(channel_id);printint(read_index);printint(buf_depth);printstrln("@@@");
#endif	//DEBUG_LEVEL_3

	/* Data is sent to client successfully */
	read_index += buf_depth;
	if (read_index > (RX_CHANNEL_FIFO_LEN-1))
	{
		read_index -= RX_CHANNEL_FIFO_LEN;
	}
	uart_rx_channel_state[channel_id].read_index = read_index;
	uart_rx_channel_state[channel_id].buf_depth -= buf_depth; //= 0; //Caution: parallel thread access
#ifdef DEBUG_LEVEL_3
	printstrln("Data is sent to client successfully");
#endif //DEBUG_LEVEL_3
}


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
		/* Manually force a value simulating MUART Tx thread consumes the data */
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
	        printstrln("Added char to uart TX module");
#endif //DEBUG_LEVEL_3
		}
	}
}

// The multi uart manager thread
void app_manager_handle_uart_data(streaming chanend cTxUART, streaming chanend cRxUART)
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
#if 1
    	  case txTimer when timerafter (txTimeStamp) :> void :
    		  //Read data from TX queue
    		  fill_uart_channel_data_from_queue();
			  //txTimeStamp += MGR_TX_TMR_EVENT_INTERVAL;
			  txTimeStamp += 1000;
			  break ;
#endif
    	  case cRxUART :> channel_id :
    		  //Read data from MUART RX thread
    		  receive_uart_channel_data(cRxUART, channel_id);
			  break ;
    	  default:
    		  break;
        }
    }
}
