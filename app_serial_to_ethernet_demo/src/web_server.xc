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
#include <xs1.h>
#include "httpd.h"
#include "telnetd.h"
#include "xtcp_buffered_client.h"
#include "web_server.h"
#include "telnet_app.h"
#include "debug.h"
#include "s2e_flash.h"
#include "common.h"
#include "client_request.h"
/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
//#define PROCESS_USER_DATA_TMR_EVENT_INTRVL		(TIMER_FREQUENCY /	\
//										(MAX_BIT_RATE * UART_APP_TX_CHAN_COUNT))
#define PROCESS_USER_DATA_TMR_EVENT_INTRVL	4000 //500

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

typedef enum {
	TELNET_DATA,
	WEB_DATA,
	UDP_DATA,
	NIL_DATA_SOURCE,
} eUserDataSource;

/* Data structure to hold user client data */
typedef struct STRUCT_USER_DATA_FIFO
{
	unsigned int 	conn_local_port; //Local port_id of user data
	int             conn_id;         //Connection Identifier
	eUserDataSource data_source;     //Who has provided this data?
	char			user_data[TX_CHANNEL_FIFO_LEN];	// Data buffer
	int 			read_index;						//Index of consumed data
	int 			write_index;					//Input data to Tx api
	unsigned 		buf_depth;						//depth of buffer to be consumed
	e_bool			is_currently_serviced;			//T/F: Indicates whether this fifo is just
													// serviced; if T, select next fifo
}s_user_data_fifo;

/* Data structure to map key uart config to app manager data structure */
typedef struct STRUCT_MAP_APP_MGR_TO_UART
{
	unsigned int 			uart_id;        //UART identifier
	int						local_port;   //User configured port e.g. (telnet)
}s_map_app_mgr_to_uart;
/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
s_user_data_fifo   user_client_data_buffer[NUM_HTTPD_CONNECTIONS]; //Number of client connections that can be suppported
s_map_app_mgr_to_uart user_port_to_uart_id_map[UART_APP_TX_CHAN_COUNT];
/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  valid_telnet_port
*
*  checks whether port_num is a valid and configured telnet port
*
*  \param unsigned int	telnet port number
*
*  \return		1 		on success
*
**/
static int valid_telnet_port(unsigned int port_num)
{
	int i;

	/* Look up for configured telnet ports */
	for (i=0;i<UART_APP_TX_CHAN_COUNT;i++)
	{
		if (user_port_to_uart_id_map[i].local_port == port_num)
			return 1;
	}

	return 0;
}

/** =========================================================================
*  fetch_conn_id_for_uart_id
*
*  Fetch conn_id that is active and mapped for user port
*
*  \param	int uart_id		UART Identifier
*
*  \return	None
*
**/
static int fetch_conn_id_for_uart_id(int uart_id)
{
	int i = 0;
	int j = 0;
	int conn_id = 0;

	for (i=0;i<UART_APP_TX_CHAN_COUNT;i++)
	{
		if (user_port_to_uart_id_map[i].uart_id == uart_id)
		{
			break;
		}
	}

	if (i != UART_APP_TX_CHAN_COUNT)
	{
	    for (j = 0; j < NUM_HTTPD_CONNECTIONS; j++)
	    {
			if (user_port_to_uart_id_map[i].local_port == user_client_data_buffer[j].conn_local_port)
				break;
	    }

	    if (j != NUM_HTTPD_CONNECTIONS)
	    {
	    	conn_id = user_client_data_buffer[j].conn_id;
	    }
	}

	return conn_id;
}

/** =========================================================================
*  update_user_conn_details
*
*  This function fetches data from user (telnet_ module and stores in a
*  local buffer \, later to be sent to data manager through a channel
*
*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			None
*
**/
void update_user_conn_details(xtcp_connection_t &conn)
{
    int i;

    // Try and find an empty connection slot
    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
        if (!user_client_data_buffer[i].conn_local_port)
            break;
    }

    if (i == NUM_HTTPD_CONNECTIONS)
    {
        // If no free connection slots were found
    	//Flag as error
    }
    // Otherwise, update the connection details
    else
    {
    	user_client_data_buffer[i].conn_local_port = conn.local_port;
    	user_client_data_buffer[i].conn_id = conn.id;
    	user_client_data_buffer[i].is_currently_serviced = TRUE; //This will be serviced in the last order of RR
    }
}

/** =========================================================================
*  free_user_conn_details
*
*  This function fetches data from user (telnet_ module and stores in a
*  local buffer \, later to be sent to data manager through a channel
*
*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			None
*
**/
void free_user_conn_details(xtcp_connection_t &conn)
{
    int i;

    // Try and find an empty connection slot
    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
        if (user_client_data_buffer[i].conn_local_port == conn.local_port)
            break;
    }

    if (i == NUM_HTTPD_CONNECTIONS)
    {
        // If no free connection slots were found
    	//Flag as error
    }
    // Otherwise, free the connection details
    else
    {
    	user_client_data_buffer[i].buf_depth = 0;
    	user_client_data_buffer[i].read_index = 0;
    	user_client_data_buffer[i].write_index = 0;
    	user_client_data_buffer[i].data_source = NIL_DATA_SOURCE;
    	user_client_data_buffer[i].is_currently_serviced = FALSE;
    	user_client_data_buffer[i].conn_id = 0;
    	user_client_data_buffer[i].conn_local_port = 0;
    }
}

/** =========================================================================
*  fetch_user_data
*
*  This function fetches data from user (telnet_ module and stores in a
*  local buffer, later to be sent to data manager through a channel
*
*  \param unsigned int	telnet_port : telnet client port number
*
*  \param unsigned int	conn_id : current active telnet client conn identifir
*
*  \return			None
*
**/
void fetch_user_data(
		xtcp_connection_t &conn,
		char data)
{
	int i = 0;
	int write_index = 0;

	/* Identify buffer to be filled */
    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
        if (user_client_data_buffer[i].conn_local_port == conn.local_port)
            break;
    }

    if (i == NUM_HTTPD_CONNECTIONS)
    {
        // If no free connection slots were found
    	//Flag as error
    }
    // Otherwise, free the connection details
    else
    {
	    if (user_client_data_buffer[i].buf_depth < TX_CHANNEL_FIFO_LEN)
	    {
	    	write_index = user_client_data_buffer[i].write_index;
	    	user_client_data_buffer[i].user_data[write_index] = data;
	        write_index++;

	        if (write_index >= TX_CHANNEL_FIFO_LEN)
	        {
	        	write_index = 0;
	        }
	        user_client_data_buffer[i].write_index = write_index;
	        user_client_data_buffer[i].buf_depth++;
	    }
#ifdef DEBUG_LEVEL_1
	    else if (user_client_data_buffer[i].buf_depth >= TX_CHANNEL_FIFO_LEN)
	    {
	    	printstr("App Server TX buffer full...[data is dropped]. Data from port : ");
	        printintln(user_client_data_buffer[i].conn_local_port);
	    }
#endif	//DEBUG_LEVEL_1
    }
}

/** =========================================================================
*  modify_telnet_port
*
*  This function checks if UI has changed telnet port;
*  Telnet port value is received from UART manager
*  If there is a change, previous connection is closed and new conn is set up
*
*  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
*
*  \return			None
*
**/
static void modify_telnet_port(
		chanend tcp_svr,
		streaming chanend cWbSvr2AppMgr)
{
	int uart_id = 0;
	int telnet_port_num = 0;
	int i = 0;

	cWbSvr2AppMgr :> uart_id;
	cWbSvr2AppMgr :> telnet_port_num;

	for (i=0;i<UART_APP_TX_CHAN_COUNT;i++)
	{
		if (user_port_to_uart_id_map[i].uart_id == uart_id)
		{
			break;
		}
	}

	if ((i != UART_APP_TX_CHAN_COUNT) &&
		(user_port_to_uart_id_map[i].local_port != telnet_port_num))
	{
		/* Modify telnet sockets */
		xtcp_connection_t conn_release;
		conn_release.id = fetch_conn_id_for_uart_id(uart_id);
		conn_release.local_port = user_port_to_uart_id_map[i].local_port;

		xtcp_unlisten(tcp_svr, conn_release.local_port);
		xtcp_abort(tcp_svr, conn_release);

		/* Open a new telnet session */
		telnetd_set_new_session(
				tcp_svr,
				telnet_port_num);

		/* Update local port number */
		user_port_to_uart_id_map[i].local_port = telnet_port_num;
	}
}

/** =========================================================================
*  send_data_to_client
*
*  This function performs the following:
*  (i) Identifies which client to send to data
*  (ii) Parses and sends uart data to appropriate user client
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \return	None
*
**/
static void send_data_to_client(
		chanend tcp_svr,
		streaming chanend cAppMgr2WbSvr)
{
	int success = 0;
	int i = 0;
	int connection_state_index = 0;
	unsigned int buf_depth = 0;  //uart rx buffer data depth
	char buffer[RX_CHANNEL_FIFO_LEN] = "";
	int uart_id = 0;
	int conn_id = 0;

	cAppMgr2WbSvr :> uart_id;
	cAppMgr2WbSvr :> buf_depth;

	conn_id = fetch_conn_id_for_uart_id(uart_id);

	connection_state_index = fetch_connection_state_index(conn_id);
	if (-1 != connection_state_index)
	{
		for (i=0; i<buf_depth; i++)
		{
			/* Store Uart X data from channel */
			cAppMgr2WbSvr :> buffer[i];
		}

		success = telnetd_send(tcp_svr, connection_state_index, buffer);
#ifdef DEBUG_LEVEL_1
		if (1 != success)
		{
			printstr("telnet send failed. Conn Id is ");printint(conn_id);
			printstr(" Connection_state_index is "); printintln(connection_state_index);
		}
#endif //DEBUG_LEVEL_1
	}
}

/** =========================================================================
*  process_user_data
*
*  This function sends data collected into user buffers from user clients,
*  to uart manager buffers through a channel
*  (i) If telnet command data for UART configuration, data is send to UART
*  manager after validation, and response is sent back to client
*  (ii) If telnet data to UART X, data is directly sent to UART manager
*
*  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
*
*  \return			None
*
**/
static void process_user_data(
		streaming chanend cWbSvr2AppMgr,
		chanend cPersData,
		chanend tcp_svr)
{
	int idxBuffer = 0;
	int uart_loop = 0;
	int read_index = 0;

	/* Identify buffer to be filled */
    for (idxBuffer = 0; idxBuffer < NUM_HTTPD_CONNECTIONS; idxBuffer++)
    {
		if (TRUE == user_client_data_buffer[idxBuffer].is_currently_serviced)
			break;
    }

	/* 'i' now contains buffer # that is just serviced
	 * reset it and increment to point to next buffer */
    if (idxBuffer != NUM_HTTPD_CONNECTIONS)
    {
        user_client_data_buffer[idxBuffer].is_currently_serviced = FALSE;
        idxBuffer++;
    	//channel_id &= (UART_APP_TX_CHAN_COUNT-1);
        if (idxBuffer >= NUM_HTTPD_CONNECTIONS)
        {
        	idxBuffer = 0;
        }
        user_client_data_buffer[idxBuffer].is_currently_serviced = TRUE;

        if ((user_client_data_buffer[idxBuffer].buf_depth > 0) &&
        		(user_client_data_buffer[idxBuffer].buf_depth <= TX_CHANNEL_FIFO_LEN))
        {
        	/* Check if it is a UART command through telnet command socket */
        	if (TELNET_PORT_USER_CMDS == user_client_data_buffer[idxBuffer].conn_local_port)
        	{
        		char data[UI_COMMAND_LENGTH];
        		char response[UI_COMMAND_LENGTH];
        		int cmd_data_idx = 0;
        		int cmd_complete = 0;
        		unsigned buf_depth = 0;
        		int connection_state_index = 0;

        		/* UART Command available to service */
        		/* If valid marker end is not present in command, ignore request till
        		 * a complete command is received */
        		read_index = user_client_data_buffer[idxBuffer].read_index;
        		buf_depth = user_client_data_buffer[idxBuffer].buf_depth;

            	/* Send data continually */
            	while ((buf_depth > 0) && (1 != cmd_complete))
            	{
            		data[cmd_data_idx] = user_client_data_buffer[idxBuffer].user_data[read_index];
            		cmd_data_idx++;
            		if (MARKER_END == user_client_data_buffer[idxBuffer].user_data[read_index])
            		{
            			cmd_complete = 1;
            			//break;
            		}
            		read_index++;

            		if (read_index >= TX_CHANNEL_FIFO_LEN)
            		{
            			read_index = 0;
            		}
            		buf_depth--;

            		if ((0 == buf_depth) && (1 != cmd_complete))
            		{
            			/* There is no valid command end marker - ignore the request*/
                		user_client_data_buffer[idxBuffer].buf_depth = buf_depth;
                		user_client_data_buffer[idxBuffer].read_index = read_index;
            		}
            	}

            	if (1 == cmd_complete)
            	{
            		user_client_data_buffer[idxBuffer].buf_depth = buf_depth;
            		user_client_data_buffer[idxBuffer].read_index = read_index;
            		cmd_complete = 0;

            		/* Parse commands and send to UART Manager via cWbSvr2AppMgr */
                    parse_client_request(cWbSvr2AppMgr,
                                         cPersData,
                                         data,
                                         response,
                                         cmd_data_idx);
                    /* Send response back to telnet client */
                    connection_state_index =
                    		fetch_connection_state_index(
                    				user_client_data_buffer[idxBuffer].conn_id);

                    telnetd_send_line(tcp_svr,
                    		connection_state_index,
                    		response);
            	} //if (1 == cmd_complete)
        	} //if (TELNET_PORT_USER_CMDS == user_client_data_buffer[i].conn_local_port)
        	else
        	{
        		/* UART X data */
            	cWbSvr2AppMgr <: UART_DATA_FROM_APP_TO_UART;
            	/* Locate and send Uart Id */
            	for (uart_loop=0;uart_loop<UART_APP_TX_CHAN_COUNT;uart_loop++)
            	{
            		if (user_port_to_uart_id_map[uart_loop].local_port == user_client_data_buffer[idxBuffer].conn_local_port)
            			break;
            	}
            	cWbSvr2AppMgr <: user_port_to_uart_id_map[uart_loop].uart_id; //UART Channel Id
            	cWbSvr2AppMgr <: user_client_data_buffer[idxBuffer].buf_depth; //Length of data

        		read_index = user_client_data_buffer[idxBuffer].read_index;
            	/* Send data continually */
            	while (user_client_data_buffer[idxBuffer].buf_depth > 0)
            	{
            		cWbSvr2AppMgr <: user_client_data_buffer[idxBuffer].user_data[read_index];
            		read_index++;

            		if (read_index >= TX_CHANNEL_FIFO_LEN)
            		{
            			read_index = 0;
            		}
            		user_client_data_buffer[idxBuffer].buf_depth--;
            	}

            	user_client_data_buffer[idxBuffer].read_index = read_index;
        	} //If telnet data for UART X
        } //If there is any client data
    } //if (i != NUM_HTTPD_CONNECTIONS)

}

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
    	  if (app_port_type==TYPE_HTTP_PORT)
    	  {
    		  httpd_init_state(tcp_svr, conn);
    	  }
    	  else if (app_port_type==TYPE_TELNET_PORT)
    	  {
    		  /* Initialize and manage telnet connection state
    		   * and set tx buffers */
    		  telnetd_init_state(tcp_svr, conn);
    	  }
    	  /* Note connection details so that data is manageable
    	   * at server level */
    	  update_user_conn_details(conn);
        break;
      case XTCP_RECV_DATA:
    	  if (app_port_type==TYPE_HTTP_PORT)
    	  {
    		  httpd_recv(tcp_svr, conn, cPersData, cWbSvr2AppMgr);
    	  }
    	  else if (app_port_type==TYPE_TELNET_PORT)
    	  {
    		  telnetd_recv(tcp_svr, conn);
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
    		  telnetd_free_state(conn);

    	  free_user_conn_details(conn);
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
void web_server(
		chanend tcp_svr,
		streaming chanend cWbSvr2AppMgr,
		streaming chanend cAppMgr2WbSvr,
		chanend cPersData)
{
  xtcp_connection_t conn;
  timer processUserDataTimer;
  unsigned processUserDataTS;

  int config_address, flash_index_page_config, flash_length_config, i;
  char flash_data[FLASH_SIZE_PAGE];
  char r_data[FLASH_SIZE_PAGE];
  int WbSvr2AppMgr_uart_data;
  int AppMgr2WbSvr_uart_data;

  /* Initiate HTTP and telnet connection state management */
  httpd_init(tcp_svr);
  telnetd_init_conn(tcp_svr);

  /* Exchange configured client ports (telnet/udp) */
  /* For now, keep it simple to get values from uart app module *///TODO: to remove telnet from app_mgr
  for(i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
  {
  	/* Fetch uart key data to app server */
  	cWbSvr2AppMgr :> user_port_to_uart_id_map[i].uart_id;
  }

  /* Telnet port for executing user commands */
  telnetd_set_new_session(tcp_svr, TELNET_PORT_USER_CMDS);
  /* Init dummy to True */
  user_client_data_buffer[0].is_currently_serviced = TRUE;

  processUserDataTimer :> processUserDataTS;
  processUserDataTS += PROCESS_USER_DATA_TMR_EVENT_INTRVL;

  // Get configuration from flash
  flash_data[0] = MARKER_START;
  flash_data[1] = CMD_CONFIG_RESTORE;
  flash_data[2] = MARKER_START;
  flash_data[3] = MARKER_END;

  // Browser is requesting data
  parse_client_request(cWbSvr2AppMgr,
                       cPersData,
                       flash_data,
                       r_data,
                       FLASH_SIZE_PAGE);

  // Loop forever processing TCP events
  while(1)
    {
      select
        {
#pragma ordered
        case cWbSvr2AppMgr :> WbSvr2AppMgr_uart_data :
        {
        	if (UART_CMD_MODIFY_TLNT_PORT_FROM_UART_TO_APP == WbSvr2AppMgr_uart_data)
        	{
        		modify_telnet_port(tcp_svr, cWbSvr2AppMgr);
        	}
        	else if (UART_CMD_MODIFY_ALL_TLNT_PORTS_FROM_UART_TO_APP == WbSvr2AppMgr_uart_data)
        	{
        		for (i=0;i<UART_APP_TX_CHAN_COUNT;i++)
        		{
        			modify_telnet_port(tcp_svr, cWbSvr2AppMgr);
        		}
        	}
        }
        break;
        case cAppMgr2WbSvr :> AppMgr2WbSvr_uart_data :
        {
        	if (UART_DATA_FROM_UART_TO_APP == AppMgr2WbSvr_uart_data)
        	{
        		send_data_to_client(tcp_svr, cAppMgr2WbSvr);
        	}
        }
        break;
        case xtcp_event(tcp_svr, conn):
          web_server_handle_event(tcp_svr, conn, cWbSvr2AppMgr, cPersData);
          break;
        case processUserDataTimer when timerafter (processUserDataTS) :> char _ :
          //Send user data to Uart App
          process_user_data(cWbSvr2AppMgr, cPersData, tcp_svr);
          processUserDataTS += PROCESS_USER_DATA_TMR_EVENT_INTRVL;
          break;
        default:
          break;
        }
    }
}

