// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename: httpd.c
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
#include <string.h>
#include "httpd.h"
#include "app_manager.h"
#include "telnet_app.h"
#include "wpage.h"
#include "page_access.h"
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
/* Structure to hold HTTP state */
typedef struct httpd_state_t
{
    int active; 		//< Whether this state structure is being used
						//  for a connection
    int conn_id; 		//< The connection id
    char *dptr; 		//< Pointer to the remaining data to send
    int dlen; 			//< The length of remaining data to send
    char *prev_dptr; 	//< Pointer to the previously sent item of data
} httpd_state_t;

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
httpd_state_t http_connection_states[NUM_HTTPD_CONNECTIONS];

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  httpd_init
*
*  This function initializes http connections states and listens on
*  configured http port number
*
*  \param	chanend tcp_svr	channel end sharing uip_server thread
*
*  \return	None
*
**/
void httpd_init(chanend tcp_svr)
{
    int i;

    // Listen on the configured http port
    xtcp_listen(tcp_svr, HTTP_PORT, XTCP_PROTOCOL_TCP);

    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
        http_connection_states[i].active = 0;
        http_connection_states[i].dptr = NULL;
    }
}

/** =========================================================================
*  parse_http_request
*
*  This function parses a HTTP request for a GET or POST messages
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure
*
*  \param	httpd_state_t	hs		reference to http state mgt structure
*
*  \param	char data		reference to data buffer to hold and process
*  							data from a http message
*
*  \param	int	len			length of data received
*
*  \return	None
*
**/
void parse_http_request(
		xtcp_connection_t *conn,
		httpd_state_t *hs,
		char *data,
		int len)
{
    int channel_id = 0;
    int prev_telnet_conn_id = 0;
    int prev_telnet_port = 0;
    char http_response[WPAGE_HTTP_RESPONSE_LENGTH];
    int request_type;

    // Return if we have data already
    if (hs->dptr != NULL)
    {
        return;
    }

    // Test if we received a HTTP GET request
    if (strncmp(data, "GET ", 4) == 0)
    {
      	// Assign the default page character array as the data to send
        hs->dptr = &page[0];
        hs->dlen = strlen(&page[0]);

    }
    else
    {
        // We got a 'POST' (or something else - unlikely)
		request_type = wpage_process_request(
							&data[0],
							&http_response[0],
							len,
							&channel_id,
							&prev_telnet_conn_id,
							&prev_telnet_port);

        if (request_type == WPAGE_CONFIG_SET)
        {
        	/* Active loop to ensure there is no pending
        	 * uart configuration update is in place */
        	while (telnet_conn_details.pending_config_update);

            /* Send details to web server in order to send it to
             * app manager thread for uart configuration */
            telnet_conn_details.channel_id = channel_id;
            telnet_conn_details.prev_telnet_conn_id = prev_telnet_conn_id;
            telnet_conn_details.prev_telnet_port = prev_telnet_port;
            telnet_conn_details.pending_config_update = 1;
        }
        hs->dptr = &http_response[0];
        hs->dlen = strlen(http_response);
    }
}

/** =========================================================================
*  httpd_recv
*
*  Receive a HTTP request
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure
*
*  \return	None
*
**/
void httpd_recv(
		chanend tcp_svr,
		xtcp_connection_t *conn)
{
    struct httpd_state_t *hs = (struct httpd_state_t *) conn->appstate;
    char data[XTCP_CLIENT_BUF_SIZE];
    int len;

    // Receive the data from the TCP stack
    len = xtcp_recv(tcp_svr, data);

    // If we already have data to send, return
    if (hs == NULL || hs->dptr != NULL)
    {
        return;
    }

    // Otherwise we have data, so parse it
    parse_http_request(conn, hs, &data[0], len);

    // If we are required to send data
    if (hs->dptr != NULL)
    {
        // Initate a send request with the TCP stack.
        // It will then reply with event XTCP_REQUEST_DATA
        // when it's ready to send
        xtcp_init_send(tcp_svr, conn);
    }
}

/** =========================================================================
*  httpd_send
*
*  Send some data back for a HTTP request
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure
*
*  \return	None
*
**/
void httpd_send(chanend tcp_svr, xtcp_connection_t *conn)
{
    struct httpd_state_t *hs = (struct httpd_state_t *) conn->appstate;

    // Check if we need to resend previous data
    if (conn->event == XTCP_RESEND_DATA)
    {
        xtcp_send(tcp_svr, hs->prev_dptr, (hs->dptr - hs->prev_dptr));
        return;
    }

    // Check if we have no data to send
    if (hs->dlen == 0 || hs->dptr == NULL)
    {
        // Terminates the send process
        xtcp_complete_send(tcp_svr);
        // Close the connection
        xtcp_close(tcp_svr, conn);
    }
    // We need to send some new data
    else
    {
        int len = hs->dlen;

        if (len > conn->mss)
            len = conn->mss;

        xtcp_send(tcp_svr, hs->dptr, len);

        hs->prev_dptr = hs->dptr;
        hs->dptr += len;
        hs->dlen -= len;
    }
}

/** =========================================================================
*  httpd_init_state
*
*  Setup a new http connection
*
*  \param	chanend tcp_svr		channel end sharing uip_server thread
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure
*
*  \return	None
*
**/
void httpd_init_state(chanend tcp_svr, xtcp_connection_t *conn)
{
    int i;

    // Try and find an empty connection slot
    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
        if (!http_connection_states[i].active)
            break;
    }

    // If no free connection slots were found, abort the connection
    if (i == NUM_HTTPD_CONNECTIONS)
    {
        xtcp_abort(tcp_svr, conn);
    }
    // Otherwise, assign the connection to a slot        //
    else
    {
        http_connection_states[i].active = 1;
        http_connection_states[i].conn_id = conn->id;
        http_connection_states[i].dptr = NULL;
        xtcp_set_connection_appstate(
        		tcp_svr,
        		conn,
        		(xtcp_appstate_t) &http_connection_states[i]);
    }
}

/** =========================================================================
*  httpd_free_state
*
*  Free a connection slot, for a finished connection
*
*  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
*  									structure for the conn id to be freed
*
*  \return	None
*
**/
void httpd_free_state(xtcp_connection_t *conn)
{
    int i;

    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
    	/* Match the connection id */
        if (http_connection_states[i].conn_id == conn->id)
        {
            http_connection_states[i].active = 0;
        }
    }
}
