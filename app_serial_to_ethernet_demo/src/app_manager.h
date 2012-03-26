// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename: app_manager.h
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file delcares data structures and interfaces required for
application manager thread to communicate with http and telnet clients,
and multi-uart tx and rx threads
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#ifndef _app_manager_h_
#define _app_manager_h_
#include "multi_uart_tx.h"
#include "multi_uart_rx.h"
#include "multi_uart_common.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
/* Length of application buffer to hold UART channel data */
#define TX_CHANNEL_FIFO_LEN			16
#define RX_CHANNEL_FIFO_LEN			16
#define	ERR_UART_CHANNEL_NOT_FOUND	50
#define	ERR_CHANNEL_CONFIG			60

/* Configure web browser port number */
#define HTTP_PORT					80
#define TELNET_PORT_USER_CMDS		23
#ifndef NUM_HTTPD_CONNECTIONS
/* Maximum number of concurrent connections */
#define NUM_HTTPD_CONNECTIONS 10
#endif //NUM_HTTPD_CONNECTIONS

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
/** Aplication manager event type.
 *  The event type represents list of actions that need to be performed by
 *  application manager thread for various client requests
 *
 **/
typedef enum app_mgr_event_type_t {
	/* Update telnet client connection id for the configured telnet port */
	ADD_TELNET_CONN_ID = 1,
	/* Reconfigure a uart channel */
	RECONF_UART_CHANNEL,
	/* Set up a new telnet client session */
	SET_NEW_TELNET_SESSION,
	/* Close existing telnet session and set up a new telnet client session */
	RESET_TELNET_SESSION,
	/* No more channel data is required for the current transaction */
	CHNL_TRAN_END,
} app_mgr_event_type_t;

typedef enum ENUM_BOOL
{
    FALSE = 0,
    TRUE,
} e_bool;

/* Data structure to hold uart channel transmit data */
typedef struct STRUCT_UART_TX_CHANNEL_FIFO
{
	unsigned int 	channel_id;						//Channel identifier
	char			channel_data[TX_CHANNEL_FIFO_LEN];	// Data buffer
	int 			read_index;						//Index of consumed data
	int 			write_index;					//Input data to Tx api
	unsigned 		buf_depth;						//depth of buffer to be consumed
	e_bool			pending_tx_data;				//T/F: T when channel_data is written
													//F when no more channel_data
	e_bool			is_currently_serviced;			//T/F: Indicates whether channel is just
													// serviced; if T, select next channel
}s_uart_tx_channel_fifo;

/* Data structure to hold uart channel receive data */
typedef struct STRUCT_UART_RX_CHANNEL_FIFO
{
	unsigned int 	channel_id;						//Channel identifier
	char			channel_data[RX_CHANNEL_FIFO_LEN];	// Data buffer
	int 			read_index;						//Index of consumed data
	int 			write_index;					//Input data to Tx api
	unsigned 		buf_depth;						//depth of buffer to be consumed
	e_bool			is_currently_serviced;			//T/F: Indicates whether channel is just
													// serviced; if T, select next channel
}s_uart_rx_channel_fifo;

/** Data structure to hold uart config data */
typedef struct STRUCT_UART_CHANNEL_CONFIG
{
	unsigned int 			channel_id;				//Channel identifier
	e_uart_config_parity	parity;
	e_uart_config_stop_bits	stop_bits;
	int						baud;					//configured baud rate
	int 					char_len;				//Length of a character in bits (e.g. 8 bits)
	e_uart_config_polarity	polarity;				//polarity of start bits
	int						telnet_port;			//User configured telnet port
	int 					telnet_conn_id;			//telnet connection id telnetd_state_t.conn_id ~= xtcp_connection_t.id
	e_bool 					is_configured;			//whether channel is configured or not//TODO: To chk if this is still reqd, provided a default uart config if applied initially, b4 web configuring
	e_bool 					is_telnet_active;		//whether telnet client is active or not
} s_uart_channel_config;

/*---------------------------------------------------------------------------
extern variables
---------------------------------------------------------------------------*/
extern s_uart_channel_config	uart_channel_config[UART_TX_CHAN_COUNT];
extern s_uart_tx_channel_fifo	uart_tx_channel_state[UART_TX_CHAN_COUNT];
extern s_uart_rx_channel_fifo	uart_rx_channel_state[UART_RX_CHAN_COUNT];

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
void fill_uart_channel_data(
		REFERENCE_PARAM(xtcp_connection_t, conn),
		char data);

/** 
 *  The multi uart manager thread. This thread
 *  (i) periodically polls for data on application Tx buffer, in order to transmit to telnet clients
 *  (ii) waits for channel data from MUART Rx thread
 *
 *  \param	chanend cWbSvr2AppMgr channel end sharing web server thread
 *  \param	chanend cTxUART		channel end sharing channel to MUART TX thrd
 *  \param	chanend cRxUART		channel end sharing channel to MUART RX thrd
 *  \return	None
 *
 */

void app_manager_handle_uart_data(
		streaming chanend cWbSvr2AppMgr,//TODO: Chk for real necessity of a streaming chnl
		streaming chanend cTxUART,
		streaming chanend cRxUART);

//int get_uart_channel_id(unsigned int remote_port);
void fill_uart_channel_data_from_queue();
int get_uart_channel_data(
		REFERENCE_PARAM(int, channel_id),
		REFERENCE_PARAM(int, conn_id),
		REFERENCE_PARAM(int, read_index),
		REFERENCE_PARAM(unsigned int, buf_depth),
		char buffer[]);
void update_uart_rx_channel_state(
		REFERENCE_PARAM(int, channel_id),
		REFERENCE_PARAM(int, read_index),
		REFERENCE_PARAM(unsigned int, buf_depth));

#endif // _app_manager_h_
