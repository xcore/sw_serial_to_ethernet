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
#include "common.h"
#include "debug.h"
#include "s2e_flash.h"
#include "client_request.h"

/*---------------------------------------------------------------------------
 constants
 ---------------------------------------------------------------------------*/
// Browser requests webpage / data
#define HTTP_REQ_ERR            0
#define HTTP_REQ_GET_WEBPAGE    1
#define HTTP_REQ_GET_DATA       2

/*---------------------------------------------------------------------------
 ports and clocks
 ---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
 typedefs
 ---------------------------------------------------------------------------*/
/* Structure to hold HTTP state */
typedef struct httpd_state_t
{
    int  active;  // Whether this state structure is being used for a connection
    int  conn_id; // The connection id
    int  dptr;    // Pointer to the remaining data to send
    int  wpage_length;
    char http_request_type;
    char wpage_data[FLASH_SIZE_PAGE];
} httpd_state_t;

/*---------------------------------------------------------------------------
 global variables
 ---------------------------------------------------------------------------*/
httpd_state_t http_connection_states[NUM_HTTPD_CONNECTIONS];

/*---------------------------------------------------------------------------
 static variables
 ---------------------------------------------------------------------------*/
static char wpage_error[] = "HTTP/1.0 200 OK\r\nServer: XMOS\r\nContent-type: text/html\r\n\r\n<html><body><h1>404 - Invalid content in flash memory.</h1></body></html>";

/*---------------------------------------------------------------------------
 protoypes
 ---------------------------------------------------------------------------*/
static void setup_error_webpage(httpd_state_t *hs);

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
        memset(&http_connection_states[i].wpage_data[0],
               NULL,
               sizeof(http_connection_states[i].wpage_data));
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
#pragma unsafe arrays
#ifndef FLASH_THREAD
#ifdef __XC__
void parse_http_request(httpd_state_t *hs,
                        char *data,
                        int len,
                        streaming chanend cWbSvr2AppMgr)
#else //__XC__
void parse_http_request(httpd_state_t *hs,
                        char *data,
                        int len,
                        chanend cWbSvr2AppMgr)
#endif //__XC__
#else //FLASH_THREAD
#ifdef __XC__
void parse_http_request(httpd_state_t *hs,
                        char *data,
                        int len,
                        chanend cPersData,
                        streaming chanend cWbSvr2AppMgr)
#else //__XC__
void parse_http_request(httpd_state_t *hs,
                        char *data,
                        int len,
                        chanend cPersData,
                        chanend cWbSvr2AppMgr)
#endif //__XC__
#endif //FLASH_THREAD
{
    int channel_id = 0;
    int request_type;
    char temp_file_name[32];
    int i, j;

    // Return if we have data already
    if (hs->dptr != 0)
    {
        return;
    }

    // Test if we received a HTTP GET request
    if (strncmp(data, "GET ", 4) == 0)
    {
        if (data[5] == '~')
        {
            // Browser is requesting data
#ifndef FLASH_THREAD
            parse_client_request(cWbSvr2AppMgr,
                                 &data[0],
                                 &hs->wpage_data[0],
                                 len);
#else //FLASH_THREAD
            /* Make a call to exchange UART command data */
        	/* Send CT */
           // outct(cAppMgr2WbSvr, 'a'); //UART_CONTROL_TOKEN_CMD_EXCHG

            parse_client_request(cWbSvr2AppMgr,
                                 cPersData,
                                 &data[0],
                                 &hs->wpage_data[0],
                                 len);
#endif //FLASH_THREAD
            hs->http_request_type = HTTP_REQ_GET_DATA;
            hs->wpage_length = strlen(&(hs->wpage_data[0]));

        } // if (data[5] == HTTP_REQ_GET_DATA)
        else
        {
            hs->http_request_type = HTTP_REQ_GET_WEBPAGE;
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
                            setup_error_webpage(hs);
                        }
                    } // else
                    break;
                } // if(data[i] = ' ')
            } // for (i = 4; i < 36; i++)
        } // else
    } // if GET
    else
    {
        setup_error_webpage(hs);
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
#pragma unsafe arrays
#ifndef FLASH_THREAD
#ifdef __XC__
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn, streaming chanend cWbSvr2AppMgr)
#else //__XC__
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn, chanend cWbSvr2AppMgr)
#endif //__XC__
#else //FLASH_THREAD
#ifdef __XC__
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn, chanend cPersData, streaming chanend cWbSvr2AppMgr)
#else //__XC__
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn, chanend cPersData, chanend cWbSvr2AppMgr)
#endif //__XC__
#endif //FLASH_THREAD
{
    httpd_state_t *hs = (struct httpd_state_t *) conn->appstate;
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
#ifndef FLASH_THREAD
    parse_http_request(hs, &data[0], len, cWbSvr2AppMgr);
#else //FLASH_THREAD
    parse_http_request(hs, &data[0], len, cPersData, cWbSvr2AppMgr);
#endif //FLASH_THREAD
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
#pragma unsafe arrays
#ifndef FLASH_THREAD
void httpd_send(chanend tcp_svr, xtcp_connection_t *conn)
#else //FLASH_THREAD
void httpd_send(chanend tcp_svr, xtcp_connection_t *conn, chanend cPersData)
#endif //FLASH_THREAD
{
    int i;
    int length_page;
    char origin_header[] = "Access-Control-Allow-Origin: *\r\n";
    int len_origin_header;
    httpd_state_t *hs = (httpd_state_t *) conn->appstate;
    length_page = (hs->wpage_length < FLASH_SIZE_PAGE) ? hs->wpage_length
                                                       : FLASH_SIZE_PAGE;

    switch (conn->event)
    {
        case XTCP_RESEND_DATA:
        {
            xtcp_send(tcp_svr, hs->wpage_data, length_page);
            break;
        }

        case XTCP_REQUEST_DATA:
        {
            if (hs->http_request_type == HTTP_REQ_GET_WEBPAGE)
            {
#ifndef FLASH_THREAD
            	flash_read_rom(hs->dptr, hs->wpage_data);
#else //FLASH_THREAD
                flash_access(FLASH_ROM_READ,
                             hs->wpage_data,
                             hs->dptr,
                             cPersData);
#endif //FLASH_THREAD

                if(strncmp(hs->wpage_data, "HTTP/1.0 200 OK", 15) == 0)
                {}
                else
                {
                    setup_error_webpage(hs);
                }
            }
            else if(hs->http_request_type == HTTP_REQ_GET_DATA)
            {
                // having this header to circumvent the "Same Origin Policy"
                len_origin_header = strlen(origin_header);
                length_page += len_origin_header;

                memmove(hs->wpage_data+len_origin_header, hs->wpage_data, strlen(hs->wpage_data)+1);
                memcpy(hs->wpage_data, origin_header, len_origin_header);
            }
            xtcp_send(tcp_svr, hs->wpage_data, length_page);
            break;
        }

        case XTCP_SENT_DATA:
        {
            if (hs->http_request_type == HTTP_REQ_GET_WEBPAGE)
            {
                hs->wpage_length -= FLASH_SIZE_PAGE;
                if (hs->wpage_length <= 0)
                {
                    xtcp_complete_send(tcp_svr);
                    xtcp_close(tcp_svr, conn);
                }
                else
                {
                    hs->dptr++;
#ifndef FLASH_THREAD
                    flash_read_rom(hs->dptr, hs->wpage_data);
#else //FLASH_THREAD
                    flash_access(FLASH_ROM_READ,
                                 hs->wpage_data,
                                 hs->dptr,
                                 cPersData);
#endif //FLASH_THREAD
                    xtcp_send(tcp_svr, hs->wpage_data, length_page);
                }
            }
            else if (hs->http_request_type == HTTP_REQ_GET_DATA)
            {
                xtcp_complete_send(tcp_svr);
                xtcp_close(tcp_svr, conn);
            }
            else if (hs->http_request_type == HTTP_REQ_ERR)
            {
                xtcp_complete_send(tcp_svr);
                xtcp_close(tcp_svr, conn);
            }
            else
            {
                // should not get here
                xtcp_complete_send(tcp_svr);
                xtcp_close(tcp_svr, conn);
            }

            break;

        } // case XTCP_SENT_DATA:

        default:
            break;

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
        memset(&http_connection_states[i].wpage_data[0],
               NULL,
               sizeof(http_connection_states[i].wpage_data));
        xtcp_set_connection_appstate(tcp_svr, conn,
                                     (xtcp_appstate_t)
                                     & http_connection_states[i]);
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
            memset(&http_connection_states[i].wpage_data[0],
                   NULL,
                   sizeof(http_connection_states[i].wpage_data));
        }
    }
}

/** =========================================================================
 *  setup_error_webpage
 *
 *
 **/
static void setup_error_webpage(httpd_state_t *hs)
{
    memset(&(hs->wpage_data[0]), NULL, sizeof(hs->wpage_data));
    memcpy(hs->wpage_data, wpage_error, strlen(&wpage_error[0]));
    hs->http_request_type = HTTP_REQ_ERR;
    hs->dptr = 0;
    hs->wpage_length = strlen(&wpage_error[0]);
}

/*=========================================================================*/
