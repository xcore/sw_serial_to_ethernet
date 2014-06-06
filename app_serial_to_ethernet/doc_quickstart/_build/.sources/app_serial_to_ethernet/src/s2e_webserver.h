#ifndef __S2E_WEBSERVER_H__
#define __S2E_WEBSERVER_H__
#include "xccompat.h"
#include "xtcp_client.h"

/**
 *  s2e_webserver_init
 *  The S2E webserver initialization routine. Registers all channels used by it.
 *
 *  @param c_xtcp           channel connecting to the xtcp module
 *  @param c_flash          channel for web page data
 *  @param c_uart_config    channel for UART configuration
 *  @param c_flash_data     channel for s2e flash data
 *  @return none
 *
 **/
void s2e_webserver_init(chanend c_xtcp,
                        NULLABLE_RESOURCE(chanend, c_flash),
                        chanend c_uart_config,
                        NULLABLE_RESOURCE(chanend, c_flash_data));

/**
 *  s2e_webserver_event_handler
 *  Handles webserver event.
 *
 *  @param c_xtcp           channel connecting to the xtcp module
 *  @param c_flash          channel for web page data
 *  @param c_uart_config    channel for UART configuration
 *  @param conn             XTCP connection state
 *  @return none
 *
 **/
void s2e_webserver_event_handler(chanend c_xtcp,
                                 NULLABLE_RESOURCE(chanend, c_flash),
                                 chanend c_uart_config,
                                 REFERENCE_PARAM(xtcp_connection_t, conn));
#endif // __S2E_WEBSERVER_H__
