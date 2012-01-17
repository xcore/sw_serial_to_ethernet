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
#ifndef _debug_h_
#define _debug_h_

#include <print.h>

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
// Remove this to prevent some information being displayed on the debug console
#define XTCP_VERBOSE_DEBUG (1)

/* Enable this macro for high level flow debug trace */
//#define DEBUG_LEVEL_1	1
/* Enable this macro for function level debugging, overflow/underflow scenarios */
//#define DEBUG_LEVEL_2	1
/* Enable this macro for detailed function level debugging, with parameters tracing enabled */
//#define DEBUG_LEVEL_3	1

/* Enable this macro to simulate MUART component data */
#define SIMULATION

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
