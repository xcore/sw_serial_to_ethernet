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
#ifndef _debug_h_
#define _debug_h_

#include <print.h>

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
/* Remove this to prevent some information being
 * displayed on the debug console */
//#define XTCP_VERBOSE_DEBUG (1)

/* Enable this macro to set variable baud rates at init time */
//#define SET_VARIABLE_BAUD_RATE	(1)

/* Enable this macro for tracing high level code flow */
//#define DEBUG_LEVEL_1	1
/* Enable this macro for function level debugging,
 * overflow/underflow scenarios */
//#define DEBUG_LEVEL_2	1
/* Enable this macro for detailed function level debugging,
 * with some parameters tracing enabled */
//#define DEBUG_LEVEL_3	1

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

#endif // _debug_h_
