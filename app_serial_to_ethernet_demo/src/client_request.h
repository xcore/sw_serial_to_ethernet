// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
/*===========================================================================
 Filename: debug.h
 Project : app_serial_to_ethernet_demo
 Author  : XMOS Ltd
 Version : 1v0
 Purpose : This file control level of debug trace
 -----------------------------------------------------------------------------

 ===========================================================================*/

/*---------------------------------------------------------------------------
 include files
 ---------------------------------------------------------------------------*/
#ifndef CLIENT_REQUEST_H_
#define CLIENT_REQUEST_H_

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
#ifdef __XC__
int parse_client_request(streaming chanend cWbSvr2AppMgr,
                         chanend cPersData,
                         char data[],
                         char response[],
                         int data_length);
#else
int parse_client_request(chanend cWbSvr2AppMgr,
                         chanend cPersData,
                         char data[],
                         char response[],
                         int data_length);
#endif
#endif // CLIENT_REQUEST_H_
