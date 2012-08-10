#ifndef __S2E_DEF_H__
#define __S2E_DEF_H__

#include "multi_uart_rx_conf.h"

typedef enum {
  NEW_UART_TX_DATA,
  GET_UART_RX_DATA_TO_SEND
} tcp_handler_to_uart_handler_cmds;

typedef enum {
  SENT_UART_TX_DATA,
  UART_RX_DATA_READY
} uart_handler_to_tcp_handler_cmds;


#define NUM_UART_CHANNELS UART_RX_CHAN_COUNT

#endif // __S2E_DEF_H__
