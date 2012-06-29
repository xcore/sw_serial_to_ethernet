#ifndef __udp_discovery_h__
#define __udp_discovery_h__

#include <xccompat.h>
#include "xtcp_client.h"

#ifndef UDP_RECV_BUF_SIZE
#define UDP_RECV_BUF_SIZE		    80 //UIP_CONF_RECEIVE_WINDOW
#endif

#ifndef INCOMING_UDP_PORT
#define INCOMING_UDP_PORT			15534
#endif

#ifndef OUTGOING_UDP_PORT
#define OUTGOING_UDP_PORT 			15533
#endif

#ifndef S2E_FIRMWARE_VER
#define S2E_FIRMWARE_VER		    "1.1.2"
#endif

#ifndef UDP_QUERY_S2E_IP
#define UDP_QUERY_S2E_IP		    "XMOS S2E REPLY"
#endif

#ifndef UDP_CMD_IP_CHANGE
#define UDP_CMD_IP_CHANGE		    "XMOS S2E IPCHANGE "
#endif

void udp_discovery_init(chanend c_xtcp, chanend c_flash_data,
                        REFERENCE_PARAM(xtcp_ipconfig_t, ipconfig));

void udp_discovery_event_handler(chanend c_xtcp,
                chanend c_flash_data,
                REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // __udp_discovery_h__
