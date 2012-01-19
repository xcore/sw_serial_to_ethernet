// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


/*===========================================================================
Filename: telnet_app.c
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file implements telnet extenstions required for application
to manage telnet client data for uart channels
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include "telnetd.h"
#include "telnet_app.h"
#include "app_manager.h"
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/
static int active_conn = -1;
/* Flag to indicate whether app callback function utilizing telnet service
 * has been registered or not */
static int register_app_callback = 0;

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  telnetd_recv_line
*
*  This function copies telnet data from telnet conn buffer and sends to
*  client
*
*  \param	chanend tcp_svr	channel end sharing uip_server thread
*
*  \param	int id			index to connection state member
*
*  \param	char line		buffer storing the received line
*
*  \param	int	len			length of buffer to access
*
*  \return	None
*
**/
void telnetd_recv_line(chanend tcp_svr,
                       int id,
                       char line[],
                       int len)
{
#ifdef DEBUG_LEVEL_3
	printstr("Rx telnet line. ");printstrln(line);
#endif //DEBUG_LEVEL_3
  telnetd_send_line(tcp_svr, id, line);
}

/** =========================================================================
*  telnetd_new_connection
*
*  set new telnet connection and send welcome message
*
*  \param	chanend tcp_svr	channel end sharing uip_server thread
*
*  \param	int id			index to connection state member
*
*  \return	None
*
**/
void telnetd_new_connection(chanend tcp_svr, int id)
{
  char welcome[][50] = {"Welcome to serial to ethernet telnet server demo!",
                        "(This server config acts as echo server...)"};
  for (int i=0;i<2;i++)
    telnetd_send_line(tcp_svr, id, welcome[i]);

  active_conn = id;
}

/** =========================================================================
*  telnetd_close_connection
*
*  closes the active telnet connection
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure
*
*  \return	None
*
**/
void telnetd_close_connection(xtcp_connection_t *conn)
{
	int i;
	active_conn = -1;

	for (i=0;i<UART_TX_CHAN_COUNT;i++)
	{
		if (uart_channel_config[i].conn_id == conn->id)
		{
			/* Update client state to inactive */
			uart_channel_config[i].is_active = FALSE;
			break;
		}
	}
	telnetd_free_state(conn);
}

/** =========================================================================
*  telnetd_set_new_session
*
*  Listen on the telnet port and register application callback function,
*   in order to receive telnet data and send it to uart via app manager
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \param	int 	telnet_port	telnet port number to listen
*
*  \return	None
*
**/
void telnetd_set_new_session(chanend tcp_svr, int telnet_port)
{
  // Listen on the telnet port
  xtcp_listen(tcp_svr, telnet_port, XTCP_PROTOCOL_TCP);

  if (0 == register_app_callback)
  {
	  /* Register application callback function */
	  register_callback(&fill_uart_channel_data);
	  register_app_callback = 1;
  }

}

/** =========================================================================
*  telnetd_connection_closed
*
*  closes the active telnet connection
*
*  \param	chanend tcp_svr	channel end sharing uip_server thread
*
*  \param	int id			index to connection state member
*
*  \return	None
*
**/
void telnetd_connection_closed(chanend tcp_svr, int id)
{
  active_conn = -1;
}

/** =========================================================================
*  telnetd_send_client_data
*
*  This function performs the following:
*  (i) fetches data from a uart channel (round robin fashion)
*  (ii) identifies telnet connection relevant to uart channel data
*  (iii) send uart data to this identified telnet socket
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \return	1		telnet data send is successful
*  			0		no telnet data to send or unsuccessful call to
*  					telnetd_send
*
**/
int telnetd_send_client_data(chanend tcp_svr)
{
	int success = 0;
	int valid_data_to_send = 0;

	int channel_id=0; //uart channel index
	int read_index=0; //uart rx buffer index
	int conn_id = 0;
	int connection_state_index = 0;
	unsigned int buf_depth=0;  //uart rx buffer data depth
	char buffer[RX_CHANNEL_FIFO_LEN] = "";

	valid_data_to_send = get_uart_channel_data(&channel_id, &conn_id, &read_index, &buf_depth, buffer);

	if (1 == valid_data_to_send)
	{
		connection_state_index = fetch_connection_state_index(conn_id);

		if (-1 != connection_state_index)
		{
			success = telnetd_send(tcp_svr, connection_state_index, buffer);
			if (1 == success)
			{
				update_uart_rx_channel_state(&channel_id, &read_index, &buf_depth);
			}
		}
#ifdef DEBUG_LEVEL_2
		else
		{
			printstr("telnet send failed. Conn Id is ");printint(conn_id);
			printstr(" Connection_state_index is "); printintln(connection_state_index);
		}
#endif //DEBUG_LEVEL_2
	}

	return success;
}

