// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename:
Project :
Author  :
Version :
Purpose
-----------------------------------------------------------------------------


===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include <stdio.h>
#include <print.h>
#include <string.h>
#include <stdlib.h>
#include "page_access.h"
#include "xtcp_client.h"
#include "app_manager.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
#define WPAGE_MAX_CONFIG_FIELD_LENGTH   10
#define WPAGE_NUM_HTTP_DYNAMIC_VAR      7

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
static int wpage_cfg[WPAGE_NUM_HTTP_DYNAMIC_VAR];

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
static int wpage_process_cfg(char *response, int *channel_id, int *prev_conn_id, int *prev_telnet_port);
static void wpage_clear_char_array(char *c, int length);

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  wpage_process_request
*
*  \param char*    starting address of data from TCP layer
*  \param char*    starting address of response array
*  \param int      length of response array
*  \param int*     starting address of uart channel identifier
*
**/

int wpage_process_request(char *w_data, char *response, int w_length, int *channel_id, int *prev_conn_id, int *prev_telnet_port)
{
    int i, j, rtnval;
    char dv[WPAGE_MAX_CONFIG_FIELD_LENGTH];
    int marker_start = 0;
    int marker_end = 0;
    int index_cfg = -1;

    // Get the variables
    for(i = 0; i < w_length; i++)
    {
        if(index_cfg >= WPAGE_NUM_HTTP_DYNAMIC_VAR)
        {
            break;
        }

        if(w_data[i] == '~')
        {
            if(marker_end == 0)
            {
                index_cfg++;
                marker_end = i + 1;
                marker_start = i + 1;
            } // if(marker_end == 0)
            else
            {
                // clear
                wpage_cfg[index_cfg] = 0;
                wpage_clear_char_array(&dv[0], WPAGE_MAX_CONFIG_FIELD_LENGTH);

                for(j = 0; j < (i - marker_start); j++)
                {
                    dv[j] = w_data[j + marker_start];
                }

                wpage_cfg[index_cfg] = atoi(dv);
                marker_end = 0;
                marker_start = 0;
            } // else; if(marker_end == 0)
        } // if(w_data[i] == "~")
    } // for(i = 0; i < REQUEST_LENGTH; i++)

    // Now process the GET/SET request
    rtnval = wpage_process_cfg(&response[0], channel_id, prev_conn_id, prev_telnet_port);
    return rtnval;
}

/** =========================================================================
*  process_get_set_request
*
*  \param char*   starting address of response array
*  \param int*     starting address of uart channel identifier
**/
static int wpage_process_cfg(char *response, int *channel_id, int *prev_conn_id, int *prev_telnet_port)
{
    int i, reqtype;
    char msg[20];
    int index_uart;

    // Clear the response array
    wpage_clear_char_array(&response[0], WPAGE_HTTP_RESPONSE_LENGTH);
    // get or set request
    reqtype = wpage_cfg[0];
    // get the channel id
    index_uart = wpage_cfg[1];

    /* Update channel id from web page */
    *channel_id = index_uart;

    if(reqtype == WPAGE_CONFIG_GET)
    {
    	// Get settings and store it in config_structure array
        // config_structure = s_uart_channel_config.abc
    	wpage_cfg[2] = uart_channel_config[index_uart].parity;
    	wpage_cfg[3] = uart_channel_config[index_uart].stop_bits;
    	wpage_cfg[4] = uart_channel_config[index_uart].baud;
    	wpage_cfg[5] = uart_channel_config[index_uart].char_len;
    	wpage_cfg[6] = uart_channel_config[index_uart].telnet_port;
    }
    else
    {
    	if (TRUE == uart_channel_config[index_uart].is_configured)
    	{
        	/* Store the previous valid config values */
    		*prev_conn_id = uart_channel_config[index_uart].telnet_conn_id;
    		*prev_telnet_port = uart_channel_config[index_uart].telnet_port;
    	}
    	else
    	{
    		*prev_conn_id = 0;
    		*prev_telnet_port = 0;
    	}

    	// Set configuration from the data available in config_structure
        uart_channel_config[index_uart].channel_id  = wpage_cfg[1];
    	uart_channel_config[index_uart].parity      = wpage_cfg[2];
    	uart_channel_config[index_uart].stop_bits   = wpage_cfg[3];
    	uart_channel_config[index_uart].baud        = wpage_cfg[4];
    	uart_channel_config[index_uart].char_len    = wpage_cfg[5];
    	uart_channel_config[index_uart].telnet_port = wpage_cfg[6];

        uart_channel_config[index_uart].is_configured = TRUE;
        if (uart_channel_config[index_uart].telnet_port != *prev_telnet_port)
        {
        	uart_channel_config[index_uart].telnet_conn_id = 0; //TODO: THis can still be active, if telnet port is not changed for config
            uart_channel_config[index_uart].is_telnet_active = FALSE;//TODO: THis can still be active, if telnet port is not changed for config
        }
    }

    for(i = 1; i < WPAGE_NUM_HTTP_DYNAMIC_VAR; i++)
    {
        // omit the get/set variable while sending response
        sprintf(msg, "~%d~", wpage_cfg[i]);
        strcat(response, msg);
    }
    return reqtype;
}

/** =========================================================================
*  clear_char_array
*
*  \param char*   starting address of character array to clear
*  \param int     length of character array
*
**/
static void wpage_clear_char_array(char *c, int length)
{
    int i;
    for(i = 0; i < length; i++)
    {
        c[i] = '\0';
    }
}

/*=========================================================================*/
