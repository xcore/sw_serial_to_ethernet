// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
/*===========================================================================
Filename: telnet_app.h
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file declares interfaces for telnet application features
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#ifndef _telnet_app_h_
#define _telnet_app_h_

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
extern variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
/* Data structure to telnet connection details */
typedef struct STRUCT_TELNET_CONN_INFO
{
	unsigned int 	channel_id; 		//Uart Channel identifier
    int 			prev_telnet_conn_id;	//Previous telnet conn identifier
    int 			prev_telnet_port;	//Previous telnet port number
    /* Set when new uart cfg data is availbl */
    int 			pending_config_update;
}s_telnet_conn_info;

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
extern s_telnet_conn_info telnet_conn_details;

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
void telnetd_set_new_session(chanend tcp_svr, int telnet_port);
int valid_telnet_port(unsigned int port_num);
int telnetd_send_client_data(chanend tcp_svr);
void telnetd_close_connection(REFERENCE_PARAM(xtcp_connection_t, conn));


#endif // _telnet_app_h_
