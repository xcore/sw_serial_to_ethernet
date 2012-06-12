#ifndef __UART_HANDLER_H__
#define __UART_HANDLER_H__
#include <xccompat.h>
#include "multi_uart_tx.h"
#include "multi_uart_rx.h"

typedef struct uart_config_data_t {
  int channel_id;
  e_uart_config_parity parity;
  e_uart_config_stop_bits stop_bits;
  e_uart_config_polarity polarity;
  int baud;
  int char_len;
} uart_config_data_t;

#ifdef __XC__
void uart_handler(chanend c_uart_data,
                  chanend c_uart_config,
                 streaming chanend c_uart_rx,
                 streaming chanend c_uart_tx);
#endif

void uart_get_config(chanend c_uart_config,
                     REFERENCE_PARAM(uart_config_data_t, data));

void uart_set_config(chanend c_uart_config,
                     REFERENCE_PARAM(uart_config_data_t, data));

#endif // __UART_HANDLER_H__

