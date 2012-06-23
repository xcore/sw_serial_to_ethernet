#ifndef __UART_HANDLER_H__
#define __UART_HANDLER_H__
#include <xccompat.h>
#include "multi_uart_tx.h"
#include "multi_uart_rx.h"
#include "uart_config.h"

#ifdef __XC__
void uart_handler(chanend c_uart_data,
                  chanend c_uart_config,
                  streaming chanend c_uart_rx,
                  streaming chanend c_uart_tx);
#endif

void uart_set_config(chanend c_uart_config,
                     REFERENCE_PARAM(uart_config_data_t, data));

#endif // __UART_HANDLER_H__
