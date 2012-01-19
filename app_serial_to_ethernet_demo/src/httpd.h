// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
/*===========================================================================
Filename: httpd.h
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file declares interfaces for http client communication
(mainly application and uart channels configuration) data
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#ifndef _httpd_h_
#define _httpd_h_
#include "xtcp_client.h"

/*---------------------------------------------------------------------------
extern variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
void httpd_init(chanend tcp_svr);
void httpd_init_state(
		chanend tcp_svr,
		REFERENCE_PARAM(xtcp_connection_t, conn));
void httpd_recv(
		chanend tcp_svr,
		REFERENCE_PARAM(xtcp_connection_t, conn));
void httpd_send(
		chanend tcp_svr,
		REFERENCE_PARAM(xtcp_connection_t, conn));
void httpd_free_state(
		REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // _httpd_h_
