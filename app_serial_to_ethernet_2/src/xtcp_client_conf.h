// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


// Remove this to prevent some information being displayed on the debug console
#define XTCP_VERBOSE_DEBUG (1)

#define UIP_CONF_RECEIVE_WINDOW 128

#define UIP_PACKET_SPLIT_THRESHOLD 8
#define UIP_USE_SINGLE_THREADED_ETHERNET
#define UIP_CONF_UDP_CONNS 2
#define UIP_SINGLE_SERVER_SINGLE_BUFFER_TX 1
