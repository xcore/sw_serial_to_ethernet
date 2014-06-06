#ifndef __udp_discovery_h__
#define __udp_discovery_h__

#include <xccompat.h>
#include "xtcp_client.h"

/**
 * Define to specify buffer length
 */
#ifndef UDP_RECV_BUF_SIZE
#define UDP_RECV_BUF_SIZE		    80 //UIP_CONF_RECEIVE_WINDOW
#endif

/**
 * Define incoming UDP port to listen to UDP discovery requests
 */
#ifndef INCOMING_UDP_PORT
#define INCOMING_UDP_PORT			15534
#endif

/**
 * Define outgoing UDP port in order to send response
 */
#ifndef OUTGOING_UDP_PORT
#define OUTGOING_UDP_PORT 			15533
#endif

/**
 * Define to specify S2E firmware version
 */
#ifndef S2E_FIRMWARE_VER
#define S2E_FIRMWARE_VER		    "2.1.0"
#endif

#ifndef UDP_QUERY_S2E_IP
#define UDP_QUERY_S2E_IP		    "XMOS S2E REPLY"
#endif

#ifndef UDP_CMD_IP_CHANGE
#define UDP_CMD_IP_CHANGE		    "XMOS S2E IPCHANGE "
#endif

/**
 * This function initializes UDP discovery state, fetches S2E IP
 * address stored in flash and references to ETH thread in order to
 * configure device IP. If valid IP is not present in flash,
 * default configured IP defined from ipconfig is used
 * @param     c_xtcp        Channel between XTCP and TCP handler thread
 * @param     c_flash_data  Channel between Flash and TCP handler thread
 * @param     ipconfig      Reference to structure holding IP configuration info
 * @return              None
 */
void udp_discovery_init(chanend c_xtcp, chanend c_flash_data,
                        REFERENCE_PARAM(xtcp_ipconfig_t, ipconfig));

/**
 * Handles events related to UDP discovery functionality.
 * Receives S2E identification and IP configuration requests from UDP
 * test server, frames and sends S2E response messages
 * @param     c_xtcp        Channel between XTCP and TCP handler thread
 * @param     c_flash_data  Channel between Flash and TCP handler thread
 * @param     conn          Reference to UDP connection state
 * @return              None
 */
void udp_discovery_event_handler(chanend c_xtcp,
                chanend c_flash_data,
                REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // __udp_discovery_h__
