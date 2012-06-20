#ifndef __udp_discovery_h__
#define __udp_discovery_h__
#include <xccompat.h>
#include "xtcp_client.h"

void udp_discovery_init(chanend c_xtcp);

void udp_discovery_event_handler(chanend c_xtcp,
                                 chanend c_uart_config,
                                 REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // __udp_config_h__
