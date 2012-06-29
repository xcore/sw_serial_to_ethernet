#ifndef __S2E_WEBSERVER_H__
#define __S2E_WEBSERVER_H__
#include "xccompat.h"
#include "xtcp_client.h"

void s2e_webserver_init(chanend c_xtcp,
                        NULLABLE_RESOURCE(chanend, c_flash),
                        chanend c_uart_config,
                        NULLABLE_RESOURCE(chanend, c_flash_data));

void s2e_webserver_event_handler(chanend c_xtcp,
                                 NULLABLE_RESOURCE(chanend, c_flash),
                                 chanend c_uart_config,
                                 REFERENCE_PARAM(xtcp_connection_t, conn));
#endif // __S2E_WEBSERVER_H__
