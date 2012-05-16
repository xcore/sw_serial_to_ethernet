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
static int register_app_callback;

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/
extern void fetch_user_data(
		xtcp_connection_t *conn,
		char data); //TODO: To be moved into web_server.h file

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
                       //char line[],
                       int len)
{
#ifdef DEBUG_LEVEL_3
	printstr("Rx telnet line. ");printstrln(line);
#endif //DEBUG_LEVEL_3
  //telnetd_send_line(tcp_svr, id, line); //TODO: Dont echo for temp case
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
	  register_callback(&fetch_user_data);
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
