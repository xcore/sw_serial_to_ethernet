// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include "httpd.h"
#include "xtcp_client.h"
#include "telnetd.h"
#include "xtcp_buffered_client.h"
#include "web_server.h"
#include "multi_uart_tx.h"
#include "app_manager.h"
#include "telnet_app.h"

/* This value determines the rate at which UART RX data to be sent to telnet client */
#define CLIENT_TX_TMR_EVENT_INTERVAL	5000 //TODO: Needs to be based on calculation

typedef enum {
	TYPE_HTTP_PORT,
	TYPE_TELNET_PORT,
	TYPE_UNSUPP_PORT,
} AppPorts;

/* Forward declarations */

// Web server thread
void web_server(chanend tcp_svr)
{
  xtcp_connection_t conn;
  /* Client data */
  timer ClientTxTimer;
  unsigned ClientTxTimeStamp;


  // Initiate the HTTP and telnet state
  httpd_init(tcp_svr);
  //telnetd_init(tcp_svr);
  telnetd_init_conn(tcp_svr);
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
        	//Read data from TX queue and send it to telnet client
        	telnetd_send_client_data(tcp_svr);
			ClientTxTimeStamp += CLIENT_TX_TMR_EVENT_INTERVAL;
			break ;
        default:
          break;
        }
    }
}

// Uart manager event handler
void web_server_handle_event(chanend tcp_svr, xtcp_connection_t &conn)
{
	AppPorts app_port_type = TYPE_UNSUPP_PORT;

  // We have received an event from the TCP stack, so respond
  // appropriately
#ifdef DEBUG_LEVEL_3
	printstr("Got event: ");printintln(conn.event);
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

  // Check if the connection is a http connection
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
    		  /* To be supported only after Uart config */
    		  telnetd_init_state(tcp_svr, conn);
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

