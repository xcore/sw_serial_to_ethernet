// Copyright (c) 2011, XMOS Ltd, All rights reserved
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
#ifndef _app_manager_h_
#define _app_manager_h_
#include "multi_uart_tx.h"
#include "multi_uart_common.h"
#include "multi_uart_rx.h"

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


#ifndef NUM_HTTPD_CONNECTIONS
/* Maximum number of concurrent connections */
#define NUM_HTTPD_CONNECTIONS 10
#endif //NUM_HTTPD_CONNECTIONS

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
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

/* Data structure to hold uart config data */
typedef struct STRUCT_UART_CHANNEL_CONFIG
{
	unsigned int 			channel_id;				//Channel identifier
	e_uart_config_parity	parity;
	e_uart_config_stop_bits	stop_bits;
	int						baud;					//configured baud rate
	int 					char_len;				//Length of a character in bits (e.g. 8 bits)
	e_uart_polarity			polarity;				//polarity of bits
	int						telnet_port;			//User configured telnet port
	int 					conn_id;				//telnet connection id telnetd_state_t.conn_id ~= xtcp_connection_t.id
	e_bool 					is_configured;			//whether channel is configured or not
	e_bool 					is_active;				//whether channel is active or not
}s_uart_channel_config;

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
void uart_channel_init(void);
int valid_telnet_port(unsigned int port_num);
int configure_uart_channel(unsigned int channel_id);
void fill_uart_channel_data(
		REFERENCE_PARAM(xtcp_connection_t, conn),
		char data);
void app_manager_handle_uart_data(
		streaming chanend cTxUART,
		streaming chanend cRxUART);
//int get_uart_channel_id(unsigned int remote_port);
void fill_uart_channel_data_from_queue();
int update_uart_channel_config_conn_id(
		unsigned int telnet_port,
		int conn_id);
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
