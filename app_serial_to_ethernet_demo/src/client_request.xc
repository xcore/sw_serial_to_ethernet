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
#include "client_request.h"
#include "s2e_flash.h"
#include "common.h"
#include <print.h>
#include <string.h>

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

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
static int get_marker_index(char gmi_data[],
                            int gmi_length,
                            char gmi_marker);

static void get_response_data(streaming chanend cWbSvr2AppMgr,
                              char grd_response[]);

static void send_to_channel(streaming chanend cWbSvr2AppMgr,
                            char stc_data[],
                            int stc_start,
                            int stc_end);

static void clear_char_array(char c[], int length);

static void replace_with_zero(char rwz_c[], int rwz_start, int rwz_end);

static int get_flash_config_address(chanend cPersData);

static void create_get_command(char cc_data[], int cc_channel);

static void create_set_command(char cc_data[], int cc_channel, int index);

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  Description
*
*  \param xxx    description of xxx
*  \param yyy    description of yyy
*
**/
int parse_client_request(streaming chanend cWbSvr2AppMgr,
                         chanend cPersData,
                         char data[],
                         char response[],
                         int data_length)
{
    char rtnval;
    char done = 0;
    char command;
    int i, j, k, ix_start, ix_end, config_address, temp_start, temp_end;
    char flash_data[FLASH_SIZE_PAGE];

    // capture first config start marker
    ix_start = get_marker_index(data, data_length, MARKER_START);

    // capture end config marker
    ix_end = get_marker_index(data, data_length, MARKER_END);

    // command is char after first marker
    command = data[ix_start + 1];

    // clear array
    clear_char_array(flash_data, FLASH_SIZE_PAGE);
    clear_char_array(response, FLASH_SIZE_PAGE);

    switch(command)
    {
        case CMD_CONFIG_GET:
        {
            // send to app_manager
            send_to_channel(cWbSvr2AppMgr, data, ix_start, ix_end);
            // get response from app_manager
            get_response_data(cWbSvr2AppMgr, response);

            break;
        } // case CMD_CONFIG_GET:

        case CMD_CONFIG_SET:
        {
            // send to app_manager
            send_to_channel(cWbSvr2AppMgr, data, ix_start, ix_end);
            // get response from app_manager
            get_response_data(cWbSvr2AppMgr, response);
            /* Send SET command complete */
            cWbSvr2AppMgr <: UART_SET_END_FROM_APP_TO_UART;
            break;
        } // case CMD_CONFIG_SET:

        case CMD_CONFIG_SAVE:
        {
            // get flash config address
            config_address = get_flash_config_address(cPersData);

            // get settings for each config from app_manager
            // TODO: flash_data[0] must contain validity flag for settings in flash
            k = 0;
            flash_data[k] = FLASH_VALID_CONFIG_PRESENT; k++;

            for(i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
            {
                // replace command and channel number to get data from app_manager
                create_get_command(data, i);
                // send to app_manager
                send_to_channel(cWbSvr2AppMgr, data, 0, 6);
                // get response form app_manager
                get_response_data(cWbSvr2AppMgr, response);
                // find marker positions in the response from app_manager
                temp_start = get_marker_index(response, UI_COMMAND_LENGTH, MARKER_START);
                temp_end = get_marker_index(response, UI_COMMAND_LENGTH, MARKER_END);
                // flash_data is one big char array that must be stored in flash
                // append response to flash_data
                for(j = temp_start; j <= temp_end; j++)
                {
                    flash_data[k] = response[j]; k++;
                }
            }

            // send this data to core 0 to write to flash
            flash_access(FLASH_CONFIG_WRITE,
                         flash_data,
                         config_address,
                         cPersData);

            break;
        } // case CMD_CONFIG_SAVE:

        case CMD_CONFIG_RESTORE:
        {
            // get flash config address
            config_address = get_flash_config_address(cPersData);

            // get the data from flash
            flash_access(FLASH_CONFIG_READ, flash_data, config_address, cPersData);
            // check for configuration present in flash
            if(flash_data[0] != FLASH_VALID_CONFIG_PRESENT)
            {}
            else
            {
                // decode data from flash and store this UART settings
                for(i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
                {
                    // find markers stored in flash
                    temp_start = get_marker_index(flash_data, UI_COMMAND_LENGTH, MARKER_START);
                    temp_end = get_marker_index(flash_data, UI_COMMAND_LENGTH, MARKER_END);
                    // replace command and channel
                    create_set_command(flash_data, i, temp_start);
                    // send data to app_manager
                    send_to_channel(cWbSvr2AppMgr, flash_data, temp_start, temp_end);
                    // get response from app_manager
                    get_response_data(cWbSvr2AppMgr, response);
                    // replace previous data with zero to avoid marker find above
                    replace_with_zero(flash_data, 0, temp_end);
                }
            }

            /* Send signal as Restore command complete */
            cWbSvr2AppMgr <: UART_RESTORE_END_FROM_APP_TO_UART;
            break;
        } // case CMD_CONFIG_RESTORE:

        default:
        {
            // should not get here
            // if we do get here, send error response - user entered wrong command
            return 0; break;
        } // default

    } // switch(command)

    return 1;
}

/** =========================================================================
*  Description
*
*  \param xxx    description of xxx
*  \param yyy    description of yyy
*
**/
static int get_marker_index(char gmi_data[], int gmi_length, char gmi_marker)
{
    int i;
    // capture marker
    for(i = 0; i < gmi_length; i++)
    {
        if(gmi_data[i] == gmi_marker)
        {
            break;
        }
    }
    if(i == gmi_length)
    {
        // Return error response
        return 0; // Must return error as no 'marker enclosed' config data found
    }
    return i;
}

/** =========================================================================
*  Description
*
*  \param xxx    description of xxx
*  \param yyy    description of yyy
*
**/
static void get_response_data(streaming chanend cWbSvr2AppMgr, char grd_response[])
{
    int done = 0;
    int i = 0;
    do
    {
        cWbSvr2AppMgr :> grd_response[i];
        if(grd_response[i] == MARKER_END)
        {
            done = 1;
        }
        else
        {
            i++;
        }
    } while(done == 0);
}

/** =========================================================================
*  Description
*
*  \param xxx    description of xxx
*  \param yyy    description of yyy
*
**/
static void send_to_channel(streaming chanend cWbSvr2AppMgr,
                            char stc_data[],
                            int stc_start,
                            int stc_end)
{
    int i;
	cWbSvr2AppMgr <: UART_CMD_FROM_APP_TO_UART;
    for(i = stc_start; i <= stc_end; i++)
    {
        cWbSvr2AppMgr <: stc_data[i];
    }
}

/** =========================================================================
 *  clear_char_array
 *
 *  \param char    character array to clear
 *  \param int     length of character array
 *
 **/
static void clear_char_array(char c[], int length)
{
    int i;
    for (i = 0; i < length; i++)
    {
        c[i] = '\0';
    }
}

/** =========================================================================
 *  replace part with zero
 *
 *  \param char    character array to clear
 *  \param int     start index to clear
 *  \param int     end index to clear
 *
 **/
static void replace_with_zero(char rwz_c[], int rwz_start, int rwz_end)
{
    int i;
    for (i = rwz_start; i <= rwz_end; i++)
    {
        rwz_c[i] = 0;
    }
}

/** =========================================================================
 *  clear_char_array
 *
 *  \param char    character array to clear
 *  \param int     length of character array
 *
 **/
static int get_flash_config_address(chanend cPersData)
{
    int flash_index_page_config, flash_length_config;
    int flash_size_config;
    int config_address = 0;

    // get the location of last file
    flash_index_page_config = fsdata[WPAGE_NUM_FILES - 1].page;
    flash_length_config = fsdata[WPAGE_NUM_FILES - 1].length;

    // get the config address. config data will be stored in a new sector above the fs file system
    // this way the sector can be erased an re-written on 'save' request
    config_address = get_config_address(flash_index_page_config,
                                        flash_length_config,
                                        cPersData);
    return config_address;
}

/** =========================================================================
 *  clear_char_array
 *
 *  \param char    character array to clear
 *  \param int     length of character array
 *
 **/
static void create_get_command(char cc_data[], int cc_channel)
{
    cc_data[0] = MARKER_START;
    cc_data[1] = CMD_CONFIG_GET;
    cc_data[2] = MARKER_START;
    cc_data[3] = MARKER_START;
    cc_data[4] = (char)(cc_channel + 48);
    cc_data[5] = MARKER_START;
    cc_data[6] = MARKER_END;
}

/** =========================================================================
 *  clear_char_array
 *
 *  \param char    character array to clear
 *  \param int     length of character array
 *
 **/
static void create_set_command(char cc_data[], int cc_channel, int index)
{
    cc_data[index + 1] = CMD_CONFIG_SET;
    cc_data[index + 4] = (char)(cc_channel + 48);
}

/*=========================================================================*/
