#ifndef __TELNET_CONFIG_H__
#define __TELNET_CONFIG_H__
#include "xccompat.h"
#include "xtcp_client.h"
#include "mutual_thread_comm.h"
#include "s2e_conf.h"

#ifndef S2E_TELNET_CONFIG_PORT
#define S2E_TELNET_CONFIG_PORT 23
#endif


void telnet_config_init(chanend c_xtcp);

void telnet_config_event_handler(chanend c_xtcp,
                                 chanend c_uart_config,
                                 chanend c_flash_data,
                                 REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // __TELNET_CONFIG_H__
