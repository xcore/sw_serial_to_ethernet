// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename: web_server.xc
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file implements web server functionality, handling application
specific TCP/IP events, managing client data for communication
-----------------------------------------------------------------------------


===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include "httpd.h"
#include "telnetd.h"
#include "xtcp_buffered_client.h"
#include "web_server.h"
#include "app_manager.h"
#include "telnet_app.h"
#include "debug.h"
/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
/* This value determines the rate at which UART RX data to be
 * sent to telnet client */
#define CLIENT_TX_TMR_EVENT_INTERVAL	5000 //TODO: Needs to be based on calculation

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
typedef enum {
	TYPE_HTTP_PORT,
	TYPE_TELNET_PORT,
	TYPE_UNSUPP_PORT,
} AppPorts;

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  web_server_handle_event
*
*  Uart manager event handler is a state machine to handle valid XTCP events,
*  specific for HTTP and telnet clients
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure
*
*  \return	None
*
**/
void web_server_handle_event(chanend tcp_svr, xtcp_connection_t &conn)
{
	AppPorts app_port_type = TYPE_UNSUPP_PORT;

  // We have received an event from the TCP stack, so respond
  // appropriately
#ifdef DEBUG_LEVEL_3
	printstr("Got TCP event @ Web server: ");printintln(conn.event);
#endif	//DEBUG_LEVEL_3

  // Ignore events that are not directly relevant to http and telnet
  switch (conn.event)
    {
    case XTCP_IFUP:
    case XTCP_IFDOWN:
    case XTCP_ALREADY_HANDLED:
      return;
    default:
      break;
    }

  // Check if the connection is a http or telnet connection
  if (HTTP_PORT == conn.local_port)
  {
	  app_port_type=TYPE_HTTP_PORT;
  }
  else if (valid_telnet_port(conn.local_port))
  {
	  app_port_type=TYPE_TELNET_PORT;
  }

  if ((app_port_type==TYPE_HTTP_PORT) ||
	  (app_port_type==TYPE_TELNET_PORT)) {
    switch (conn.event)
      {
      case XTCP_NEW_CONNECTION:
    	  if (app_port_type==TYPE_HTTP_PORT)
    		  httpd_init_state(tcp_svr, conn);
    	  else if (app_port_type==TYPE_TELNET_PORT)
    	  {
    		  /* This shall be supported only after Uart config */
    		  /* Initialize and manage telnet connection state
    		   * and set tx buffers */
    		  telnetd_init_state(tcp_svr, conn);
    		  /* Update telnet client connection id for the configured
    		   * telnet port */
    		  update_uart_channel_config_conn_id(conn.local_port, conn.id);
    	  }
        break;
      case XTCP_RECV_DATA:
    	  if (app_port_type==TYPE_HTTP_PORT)
    		  httpd_recv(tcp_svr, conn);
    	  else if (app_port_type==TYPE_TELNET_PORT)
    		  telnetd_recv(tcp_svr, conn);
        break;
      case XTCP_SENT_DATA:
      case XTCP_REQUEST_DATA:
      case XTCP_RESEND_DATA:
    	  if (app_port_type==TYPE_HTTP_PORT)
    		  httpd_send(tcp_svr, conn);
    	  else if (app_port_type==TYPE_TELNET_PORT)
    		  telnet_buffered_send_handler(tcp_svr, conn);
          break;
      case XTCP_TIMED_OUT:
      case XTCP_ABORTED:
      case XTCP_CLOSED:
    	  if (app_port_type==TYPE_HTTP_PORT)
    		  httpd_free_state(conn);
    	  else if (app_port_type==TYPE_TELNET_PORT)
          {
    		  telnetd_close_connection(conn);
          }
    	  break;
      default:
        // Ignore anything else
        break;
      }
    conn.event = XTCP_ALREADY_HANDLED;
  }

  return;
}

/** =========================================================================
*  web_server
*
*  Web server thread. This thread handles
*  (i) TCP events meant for the application and sends to web server state m/c
*  (ii) Periodically sends telnet data to telnet clients
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \return	None
*
**/
void web_server(chanend tcp_svr)
{
  xtcp_connection_t conn;
  /* Timer to send client (telnet) data periodically */
  timer ClientTxTimer;
  unsigned ClientTxTimeStamp;


  /* Initiate HTTP and telnet connection state management */
  httpd_init(tcp_svr);
  telnetd_init_conn(tcp_svr);
  /* Initiate uart channel configuration with default values */
  uart_channel_init();

  ClientTxTimer :> ClientTxTimeStamp;
  ClientTxTimeStamp += CLIENT_TX_TMR_EVENT_INTERVAL + 100000;

  // Loop forever processing TCP events
  while(1)
    {
      select
        {
        case xtcp_event(tcp_svr, conn):
          web_server_handle_event(tcp_svr, conn);
          break;
        case ClientTxTimer when timerafter (ClientTxTimeStamp) :> void :
        	/* Upon timer event, read data from app manager's TX queue and
        	send it to telnet client */
        	telnetd_send_client_data(tcp_svr);
			ClientTxTimeStamp += CLIENT_TX_TMR_EVENT_INTERVAL;
			break ;
        default:
          break;
        }
    }
}

