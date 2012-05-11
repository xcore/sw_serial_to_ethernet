// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename: common.h
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file delcares data structures and interfaces required for
data manager thread to communicate with application manager thread
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#ifndef _common_h_
#define _common_h_

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
//Separate thread for accessing flash routines
/* Enable this macro if Web Server is not on Core 0 */
#define FLASH_THREAD
/* Length of application buffer to hold UART channel data */
#define UART_APP_TX_CHAN_COUNT		8 // Must be Same as UART_TX_CHAN_COUNT
#define TX_CHANNEL_FIFO_LEN			128 //This is a common length between app server and data manager
#define RX_CHANNEL_FIFO_LEN			128
#define RX_CHANNEL_MIN_PACKET_LEN                12
#define RX_CHANNEL_FLUSH_TIMEOUT           10000000
#ifndef NUM_HTTPD_CONNECTIONS
/* Maximum number of concurrent connections */
#define NUM_HTTPD_CONNECTIONS 10
#endif //NUM_HTTPD_CONNECTIONS
/* Configure web browser port number */
#define HTTP_PORT					80
#define TELNET_PORT_USER_CMDS		23
#define DEF_TELNET_PORT_START_VALUE	46

/* Channel communication parameters */
#define CMD_CONFIG_GET      '1'
#define CMD_CONFIG_SET      '2'
#define CMD_CONFIG_SAVE     '3'
#define CMD_CONFIG_RESTORE  '4'
#define CMD_UPGRADE         '5'

/* marker start and marker end for config parameters from sockets */
#define MARKER_START        '~'
#define MARKER_END          '@'

#define NUM_UI_PARAMS		(6 + 1) //1 for command type (added internally)
#define UI_COMMAND_LENGTH	256 //TODO: Polarity parameter is not yet accounted

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
typedef enum ENUM_BOOL
{
    FALSE = 0,
    TRUE,
} e_bool;

/** Aplication manager event type.
 *  The event type represents list of actions that need to be performed by
 *  application manager thread for various client requests
 *
 **/
typedef enum app_mgr_event_type_t {
	UART_CONTROL_TOKEN = 1,
	/* Uart X data */
	PULL_UART_DATA_FROM_UART_TO_APP,
	/* Uart X data ready at AM to send to xtcp clients */
	UART_DATA_READY_UART_TO_APP,
	/* Uart X data from client to Muart */
	UART_DATA_FROM_APP_TO_UART,
	/* UART X command from UI to UART manager */
	UART_CMD_FROM_APP_TO_UART,
	/* Uart manager command to App server */
	UART_CMD_MODIFY_TLNT_PORT_FROM_UART_TO_APP,
	UART_CMD_MODIFY_ALL_TLNT_PORTS_FROM_UART_TO_APP,
	/* Completion of Set request */
	UART_SET_END_FROM_APP_TO_UART,
	/* Completion of Restore request */
	UART_RESTORE_END_FROM_APP_TO_UART,
} app_mgr_event_type_t;
/*---------------------------------------------------------------------------
extern variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/

#endif // _common_h_
