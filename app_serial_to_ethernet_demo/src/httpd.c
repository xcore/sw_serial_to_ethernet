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
#include "page_access.h"
#include "flash_app.h"
#include "flash_common.h"
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
#define HTTP_REQ_TYPE_ERR        0
#define HTTP_REQ_TYPE_GET        1
#define HTTP_REQ_TYPE_POST       2

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
/* Structure to hold HTTP state */
typedef struct httpd_state_t {
    int active;      //< Whether this state structure is being used
                   //  for a connection
    int conn_id;     //< The connection id
    int dptr;      //< Pointer to the remaining data to send
    int dlen;        //< The length of remaining data to send
    char *prev_dptr; //< Pointer to the previously sent item of data
    int  wpage_length;
    char http_request_type;
    char wpage_data[FLASH_SIZE_PAGE];
} httpd_state_t;

/*---------------------------------------------------------------------------
 global variables
 ---------------------------------------------------------------------------*/
httpd_state_t http_connection_states[NUM_HTTPD_CONNECTIONS];

fsdata_t fsdata[] =
{
 { "/index.html", 0, 4408 },
 { "/img/xmos_logo.gif", 18, 915 },
};

/*---------------------------------------------------------------------------
 static variables
 ---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
 protoypes
 ---------------------------------------------------------------------------*/
void pack_flash_config(char *data);

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
        http_connection_states[i].dptr = 0;
        http_connection_states[i].wpage_length = 0;
        memset(&http_connection_states[i].wpage_data[0], NULL, sizeof(http_connection_states[i].wpage_data));
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
void parse_http_request(httpd_state_t *hs, char *data, int len, chanend cPersData)
{
    int channel_id = 0;
    int prev_telnet_conn_id = 0;
    int prev_telnet_port = 0;
    int request_type;
    char temp_file_name[32];
    int i, j;
    char wpage_error[] = "HTTP/1.0 404\r\n";

    char flash_data[FLASH_SIZE_PAGE];
    int flash_index_page_config, flash_length_config;
    int flash_size_config;
    int config_address = 0;

    // get the location of last file
    flash_index_page_config = fsdata[WPAGE_NUM_FILES - 1].page;
    flash_length_config = fsdata[WPAGE_NUM_FILES - 1].length;
    memset(&flash_data[0], NULL, sizeof(flash_data));

    // Return if we have data already
    if (hs->dptr != 0)
    {
        return;
    }

    // Test if we received a HTTP GET request
    if (strncmp(data, "GET ", 4) == 0)
    {
        hs->http_request_type = HTTP_REQ_TYPE_GET;
        for (i = 4; i < 36; i++)
        {
            if (data[i] == ' ')
            {
                if (i <= 6)
                {
                    // did not get a file name, send index.html (s2e.html)
                    hs->wpage_length = fsdata[0].length;
                    hs->dptr = fsdata[0].page;
                }
                else
                {
                    memset(&temp_file_name[0], NULL, sizeof(temp_file_name));

                    for (j = 4; j < i; j++)
                    {
                        temp_file_name[j - 4] = data[j];
                    }

                    for (j = 0; j < WPAGE_NUM_FILES; j++)
                    {
                        if (strcmp(temp_file_name, fsdata[j].name) == 0)
                        {
                            hs->wpage_length = fsdata[j].length;
                            hs->dptr = fsdata[j].page;
                            break;
                        }
                    } // for

                    if (j >= WPAGE_NUM_FILES)
                    {
                        hs->http_request_type = HTTP_REQ_TYPE_ERR;
                        memcpy(hs->wpage_data, wpage_error, strlen(wpage_error));
                        hs->dptr = 0;
                        hs->wpage_length = strlen(wpage_error);
                    }
                } // else
                break;
            } // if(data[i] = ' ')
        } // for (i = 4; i < 36; i++)
    } // if GET

    else if (strncmp(data, "POST ", 5) == 0)
    {
        // We got a 'POST'
        request_type = wpage_process_request(&data[0],
                                             &hs->wpage_data[0],
                                             len,
                                             &channel_id,
                                             &prev_telnet_conn_id,
                                             &prev_telnet_port);

        hs->http_request_type = HTTP_REQ_TYPE_POST;
        hs->wpage_length = strlen(hs->wpage_data);

        switch(request_type)
        {
            case WPAGE_CONFIG_GET:
            {
                // nothing more to do. the data is already present in wpage_data
                break;
            }
            case WPAGE_CONFIG_SET:
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
                break;
            }
            case WPAGE_CONFIG_SAVE:
            {
                // prepare char array that will be stored in flash
                pack_flash_config(&flash_data[0]);
                // get the config address. config data will be stored in a new sector above the fs file system
                // this way the sector can be erased an re-written on 'save' request
                config_address = get_config_address(flash_index_page_config, flash_length_config, cPersData);
                // send this data to core 0 to write to flash
                flash_access(FLASH_CONFIG_WRITE, flash_data, config_address, cPersData);
                break;
            }
            default: break;

        } // switch(request_type)
    }
    else
    {
        hs->http_request_type = HTTP_REQ_TYPE_ERR;
        memcpy(hs->wpage_data, wpage_error, strlen(wpage_error));
        hs->dptr = 0;
        hs->wpage_length = strlen(wpage_error);
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
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn, chanend cPersData)
{
    httpd_state_t *hs = (struct httpd_state_t *)conn->appstate;
    char data[XTCP_CLIENT_BUF_SIZE];
    int len;

    // Receive the data from the TCP stack
    len = xtcp_recv(tcp_svr, data);

    // If we already have data to send, return
    if (hs == NULL || hs->wpage_length != 0)
    {
        return;
    }

    // Otherwise we have data, so parse it
    parse_http_request(hs, &data[0], len,  cPersData);

    // If we are required to send data
    if (hs->wpage_length != 0)
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
void httpd_send(chanend tcp_svr, xtcp_connection_t *conn, chanend cPersData)
{
    int i;
    int length_page;

    httpd_state_t *hs = (httpd_state_t *)conn->appstate;
    length_page = (hs->wpage_length < FLASH_SIZE_PAGE) ? hs->wpage_length : FLASH_SIZE_PAGE;

    switch(conn->event)
    {
        case XTCP_RESEND_DATA:
        {
            xtcp_send(tcp_svr, hs->wpage_data, length_page);
            break;
        }

        case XTCP_REQUEST_DATA:
        {
            if(hs->http_request_type == HTTP_REQ_TYPE_GET)
            {
                flash_access(FLASH_ROM_READ, hs->wpage_data, hs->dptr, cPersData);
            }
            xtcp_send(tcp_svr, hs->wpage_data, length_page);
            break;
        }

        case XTCP_SENT_DATA:
        {
            if(hs->http_request_type == HTTP_REQ_TYPE_GET)
            {        
                hs->wpage_length -= FLASH_SIZE_PAGE;
                if(hs->wpage_length <= 0)
                {
                    xtcp_complete_send(tcp_svr);
                    xtcp_close(tcp_svr, conn);
                }
                else
                {
                    hs->dptr++;
                    flash_access(FLASH_ROM_READ, hs->wpage_data, hs->dptr, cPersData);
                    xtcp_send(tcp_svr, hs->wpage_data, length_page);
                }
            }
            else if(hs->http_request_type == HTTP_REQ_TYPE_POST)
            {
                xtcp_complete_send(tcp_svr);
                xtcp_close(tcp_svr, conn);
            }
            else if(hs->http_request_type == HTTP_REQ_TYPE_ERR)
            {
                xtcp_complete_send(tcp_svr);
                xtcp_close(tcp_svr, conn);
            }
            else
            {
                printstrln("unidentified request - should not get here");
                xtcp_complete_send(tcp_svr);
                xtcp_close(tcp_svr, conn);
            }

            break;

        } // case XTCP_SENT_DATA:

        default: break;

    } // switch(conn->event)
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
    // Otherwise, assign the connection to a slot
    else
    {
        http_connection_states[i].active = 1;
        http_connection_states[i].conn_id = conn->id;
        http_connection_states[i].dptr = 0;
        memset(&http_connection_states[i].wpage_data[0], NULL, sizeof(http_connection_states[i].wpage_data));
        xtcp_set_connection_appstate(tcp_svr,
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
        if (http_connection_states[i].conn_id == conn->id)
        {
            http_connection_states[i].active = 0;
            http_connection_states[i].dptr = 0;
            http_connection_states[i].wpage_length = 0;
            memset(&http_connection_states[i].wpage_data[0], NULL, sizeof(http_connection_states[i].wpage_data));
        }
    }
}

/** =========================================================================
*  pack_flash_config
*
*
**/
void pack_flash_config(char *data)
{
    int i;
    int j = 0;

    // say that there is a config on flash
    data[j] = FLASH_VALID_CONFIG_PRESENT; j++;

    for(i = 0; i < UART_TX_CHAN_COUNT; i++)
    {
        data[j] = uart_channel_config[i].channel_id             & 0xFF; j++;
        data[j] = uart_channel_config[i].parity                 & 0xFF; j++;
        data[j] = uart_channel_config[i].stop_bits              & 0xFF; j++;
        data[j] = (uart_channel_config[i].baud >> 0)            & 0xFF; j++;
        data[j] = (uart_channel_config[i].baud >> 8)            & 0xFF; j++;
        data[j] = (uart_channel_config[i].baud >> 16)           & 0xFF; j++;
        data[j] = (uart_channel_config[i].baud >> 24)           & 0xFF; j++;
        data[j] = uart_channel_config[i].char_len               & 0xFF; j++;
        data[j] = uart_channel_config[i].polarity               & 0xFF; j++;
        data[j] = (uart_channel_config[i].telnet_port >> 0)     & 0xFF; j++;
        data[j] = (uart_channel_config[i].telnet_port >> 8)     & 0xFF; j++;
        data[j] = (uart_channel_config[i].telnet_port >> 16)    & 0xFF; j++;
        data[j] = (uart_channel_config[i].telnet_port >> 24)    & 0xFF; j++;
    }
}
