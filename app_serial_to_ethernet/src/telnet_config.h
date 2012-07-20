#ifndef __TELNET_CONFIG_H__
#define __TELNET_CONFIG_H__
#include "xccompat.h"
#include "xtcp_client.h"
#include "mutual_thread_comm.h"
#include "s2e_conf.h"

/**
 * Define to specify telnet port to use for UART configuration
 */
#ifndef S2E_TELNET_CONFIG_PORT
#define S2E_TELNET_CONFIG_PORT 23
#endif


void telnet_config_init(chanend c_xtcp);

/**
 * This function handles UART configuration requests from telnet configuration
 * client. It initializes cofnig parse state machine, receives configuration
 * request events, sends response back to the client
 * @param    c_xtcp       Channel-end between XTCP and TCP handler thread
 * @param    c_uart_configChannel-end to communicate UART configuration data
 *            TCP handler and UART handler thread
 * @param    c_flash_data Channel-end to communicate UART configuration data
 *            stored in flash to TCP handler thread
 * @param   conn          Reference to structure holding IP configuration info
 * @return              None
 */
void telnet_config_event_handler(chanend c_xtcp,
                                 chanend c_uart_config,
                                 chanend c_flash_data,
                                 REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // __TELNET_CONFIG_H__
