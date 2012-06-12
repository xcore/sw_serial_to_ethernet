#ifndef __TELNET_CONFIG_H__
#define __TELNET_CONFIG_H__
#include "xccompat.h"
#include "xtcp_client.h"
#include "mutual_thread_comm.h"

void telnet_config_init(chanend c_xtcp);

void telnet_config_event_handler(chanend c_xtcp,
                                 chanend c_uart_config,
                                 REFERENCE_PARAM(xtcp_connection_t, conn));

#endif // __TELNET_CONFIG_H__
