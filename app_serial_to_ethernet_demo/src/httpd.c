// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <string.h>
#include <print.h>
#include "xtcp_client.h"
#include "httpd.h"
#include "app_manager.h"
#include "telnet_app.h"
#include "debug.h"
#include "wpage.h"
#include "page_access.h"

// Structure to hold HTTP state
typedef struct httpd_state_t
{
    int active; //< Whether this state structure is being used
    //  for a connection
    int conn_id; //< The connection id
    char *dptr; //< Pointer to the remaining data to send
    int dlen; //< The length of remaining data to send
    char *prev_dptr; //< Pointer to the previously sent item of data
} httpd_state_t;

httpd_state_t http_connection_states[NUM_HTTPD_CONNECTIONS];


// Initialize the HTTP state
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
////

// Parses a HTTP request for a GET
void parse_http_request(xtcp_connection_t *conn, chanend tcp_svr, httpd_state_t *hs, char *data, int len)
{
    int channel_id = 0;
    int prev_conn_id = 0;
    int prev_telnet_port = 0;
    int chnl_config_status = 0;
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
		request_type = wpage_process_request(&data[0], &http_response[0], len, &channel_id, &prev_conn_id, &prev_telnet_port);

        if (request_type == WPAGE_CONFIG_SET)
        {
        	/* Close the current telnet session */
        	xtcp_connection_t conn_release;
        	if ((0 != prev_conn_id) && (0 != prev_telnet_port))
        	{
        		conn_release.id = prev_conn_id;
        		conn_release.local_port = prev_telnet_port;

        		xtcp_unlisten(tcp_svr, conn_release.local_port);
        		xtcp_abort(tcp_svr, &conn_release);
        	}

            chnl_config_status = configure_uart_channel(channel_id);
#ifdef SIMULATION
            chnl_config_status = 0; //TODO: to be removed when MUART reconfig is in place
#endif //SIMULATION
            if (0 == chnl_config_status)
            {
                telnetd_set_new_session(tcp_svr,
                                        uart_channel_config[channel_id].telnet_port);
#ifdef DEBUG_LEVEL_3
	    	  printstr("Configured uart_channel: "); printint(channel_id);
	    	  printstr(" Telnet port: "); printintln(uart_channel_config[channel_id].telnet_port);
#endif //DEBUG_LEVEL_3
            }
            else
            {
#ifdef DEBUG_LEVEL_2
	    	  printstr("Failed configure_uart_channel: "); printint(channel_id);
                printintln(chnl_config_status);
#endif //DEBUG_LEVEL_2
            }
        }
        hs->dptr = &http_response[0];
        hs->dlen = strlen(http_response);
    }
}

// Receive a HTTP request
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn)
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
    parse_http_request(conn, tcp_svr, hs, &data[0], len);

    // If we are required to send data
    if (hs->dptr != NULL)
    {
        // Initate a send request with the TCP stack.
        // It will then reply with event XTCP_REQUEST_DATA
        // when it's ready to send
        xtcp_init_send(tcp_svr, conn);
    }
    ////
}

// Send some data back for a HTTP request
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
    ////

}

// Setup a new connection
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
        xtcp_set_connection_appstate(tcp_svr,
                                     conn,
                                     (xtcp_appstate_t) &http_connection_states[i]);
    }
}

// Free a connection slot, for a finished connection
void httpd_free_state(xtcp_connection_t *conn)
{
    int i;

    for (i = 0; i < NUM_HTTPD_CONNECTIONS; i++)
    {
        if (http_connection_states[i].conn_id == conn->id)
        {
            http_connection_states[i].active = 0;
        }
    }
}
