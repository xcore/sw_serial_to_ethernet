// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
/*===========================================================================
Filename: web_server.h
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file declares interfaces web server functions
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#ifndef _web_server_h_
#define _web_server_h_

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/

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
#ifndef FLASH_THREAD
void web_server(
		chanend tcp_svr,
		streaming chanend cWbSvr2AppMgr,
		streaming chanend cAppMgr2WbSvr);
#else //FLASH_THREAD
void web_server(
		chanend tcp_svr,
		streaming chanend cWbSvr2AppMgr,
		streaming chanend cAppMgr2WbSvr,
		chanend pers_data);
#endif //FLASH_THREAD

#endif // _web_server_h_
