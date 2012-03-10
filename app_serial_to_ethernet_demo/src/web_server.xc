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
#include "user_client.h"
#include "telnet_app.h"
#include "debug.h"
#include "flash_app.h"
#include "flash_common.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
/* This value determines the rate at which UART RX data to be
 * sent to telnet client */
#define CLIENT_TX_TMR_EVENT_INTERVAL	8000 //TODO: Needs to be based on calculation

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
s_telnet_conn_info telnet_conn_details;
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
*  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
*
*  \return	None
*
**/
void web_server_handle_event(
		chanend tcp_svr,
		xtcp_connection_t &conn,
		streaming chanend cWbSvr2AppMgr,
		chanend cPersData)
{
	AppPorts app_port_type = TYPE_UNSUPP_PORT;
	int WbSvr2AppMgr_chnl_data = 9999;
	int new_telnet_port = 0;

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
  else if ((valid_telnet_port(conn.local_port)) ||
		  (TELNET_PORT_USER_CMDS == conn.local_port))
  {
	  app_port_type=TYPE_TELNET_PORT;
  }

  if ((app_port_type==TYPE_HTTP_PORT) ||
	  (app_port_type==TYPE_TELNET_PORT)) {
    switch (conn.event)
      {
      case XTCP_NEW_CONNECTION:
		  /* Listen on default telnet ports */
		  listen_on_default_telnet_ports(tcp_svr);

    	  if (app_port_type==TYPE_HTTP_PORT)
    	  {
    		  httpd_init_state(tcp_svr, conn);
    	  }
    	  else if (app_port_type==TYPE_TELNET_PORT)
    	  {
    		  /* This shall be supported only after Uart config */
    		  /* Initialize and manage telnet connection state
    		   * and set tx buffers */
    		  telnetd_init_state(tcp_svr, conn);
    		  /* Update telnet client connection id for the configured
    		   * telnet port */
    		  cWbSvr2AppMgr <: ADD_TELNET_CONN_ID;
    		  cWbSvr2AppMgr <: conn.local_port;
    		  cWbSvr2AppMgr <: conn.id;
    	  }
        break;
      case XTCP_RECV_DATA:
    	  if (app_port_type==TYPE_HTTP_PORT)
    	  {
    		  httpd_recv(tcp_svr, conn, cPersData);
    	  }
    	  else if (app_port_type==TYPE_TELNET_PORT)
    	  {
    		  telnetd_recv(tcp_svr, conn);
    	  }

    	  /* Check for any pending user requests */
		  if (1 == telnet_conn_details.pending_config_update)
		  {
    		  /* Check if uart channel reconf is required or not */
    		  /* Send the uart data to app manager thread */
              cWbSvr2AppMgr <: RECONF_UART_CHANNEL;
              cWbSvr2AppMgr <: telnet_conn_details.channel_id;
              cWbSvr2AppMgr <: telnet_conn_details.prev_telnet_conn_id;
              cWbSvr2AppMgr <: telnet_conn_details.prev_telnet_port;

    		  cWbSvr2AppMgr :> WbSvr2AppMgr_chnl_data;

    		  //TODO: Telnet sessions are not yet activated by default (with def cfg), unless web conf is done
    		  if (SET_NEW_TELNET_SESSION == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* Receive the channel data */
    			  cWbSvr2AppMgr :> new_telnet_port;
    			  /* Open a new telnet session */
    			  telnetd_set_new_session(
    					  tcp_svr,
    					  new_telnet_port);
#ifdef DEBUG_LEVEL_3
    			  printstr("Configured Telnet port: ");
    			  printintln(new_telnet_port);
#endif //DEBUG_LEVEL_3
    		  }
    		  else if (RESET_TELNET_SESSION == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* Receive the channel data */
    			  cWbSvr2AppMgr :> new_telnet_port;
    			  if (telnet_conn_details.prev_telnet_port != new_telnet_port)
    			  {
    				  xtcp_connection_t conn_release;
    				  conn_release.id = telnet_conn_details.prev_telnet_conn_id;
    				  conn_release.local_port = telnet_conn_details.prev_telnet_port;

    				  xtcp_unlisten(tcp_svr, conn_release.local_port);
    				  xtcp_abort(tcp_svr, conn_release);

    				  /* Open a new telnet session */
    				  telnetd_set_new_session(
    						  tcp_svr,
    						  new_telnet_port);
#ifdef DEBUG_LEVEL_3
    				  printstr("Configured fresh Telnet port: ");
    				  printintln(new_telnet_port);
#endif //DEBUG_LEVEL_3
    			  }
    		  }
    		  else if (CHNL_TRAN_END == WbSvr2AppMgr_chnl_data)
    		  {
    			  /* End of current transaction. Do nothing */
    			  ;
    		  }

    		  /* Reset pending config update flag */
    		  telnet_conn_details.pending_config_update = 0;
		  }

		  /* Check if there is any feedback to client */
		  if (1 == user_client_cmd_resp.pending_user_cmd_response)
		  {
			  int connection_state_index = 0;

			  connection_state_index = fetch_connection_state_index(conn.id);

			  telnetd_send_line(tcp_svr,
					  connection_state_index,
					  user_client_cmd_resp.user_resp_buffer);

			  /* Reset the pending flag */
			  user_client_cmd_resp.pending_user_cmd_response = 0;
		  }

        break;
      case XTCP_SENT_DATA:
      case XTCP_REQUEST_DATA:
      case XTCP_RESEND_DATA:
    	  if (app_port_type==TYPE_HTTP_PORT)
    		  httpd_send(tcp_svr, conn, cPersData);
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
*  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
*
*  \return	None
*
**/
void web_server(chanend tcp_svr, streaming chanend cWbSvr2AppMgr, chanend cPersData)
{
  xtcp_connection_t conn;
  /* Timer to send client (telnet) data periodically */
  timer ClientTxTimer;
  unsigned ClientTxTimeStamp;

  int config_address, flash_index_page_config, flash_length_config, i;
  char flash_data[FLASH_SIZE_PAGE];


  /* Initiate HTTP and telnet connection state management */
  httpd_init(tcp_svr);
  telnetd_init_conn(tcp_svr);
  /* Telnet port for executing user commands */
  telnetd_set_new_session(tcp_svr, TELNET_PORT_USER_CMDS);

  // Get configuration from flash
  // get the location of last file
  flash_index_page_config = fsdata[WPAGE_NUM_FILES - 1].page;
  flash_length_config = fsdata[WPAGE_NUM_FILES - 1].length;
  //memset(&flash_data[0], NULL, sizeof(flash_data));

  // get the configuration address
  config_address = get_config_address(flash_index_page_config, flash_length_config, cPersData);
  // get the data from flash
  flash_access(FLASH_CONFIG_READ, flash_data, config_address, cPersData);
  // data from flash is now in flash_data[]
  // send it to app_manager via channel
  // CAUTION 105
  cWbSvr2AppMgr <: flash_data[0];

  if(flash_data[0] == FLASH_VALID_CONFIG_PRESENT)
  {
      for(i = 1; i < 105; i++)
      {
          cWbSvr2AppMgr <: flash_data[i];
      }
  }

  ClientTxTimer :> ClientTxTimeStamp;
  ClientTxTimeStamp += CLIENT_TX_TMR_EVENT_INTERVAL + 100000;

  // Loop forever processing TCP events
  while(1)
    {
      select
        {
        case xtcp_event(tcp_svr, conn):
          web_server_handle_event(tcp_svr, conn, cWbSvr2AppMgr, cPersData);
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

