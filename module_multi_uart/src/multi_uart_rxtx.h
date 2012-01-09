#ifndef __MULTI_UART_RXTX_H__
#define __MULTI_UART_RXTX_H__

#include "multi_uart_tx.h"
#include "multi_uart_rx.h"

/**
 * Configure and run the Multi-UART TX & RX server threads
 * @param   cTxUart             TX Server Channel
 * @param   cRxUart             RX Server Channel
 * @param   uart_rx_ports       RX Ports structure
 * @param   uart_tx_ports       TX Ports structure
 * @param   uart_ext_clk_pin    External clock reference input pin
 * @param   uart_clock          Clock block to run the ports from
 */

void run_ext_clk_multi_uart_rxtx( streaming chanend cTxUart, s_multi_uart_tx_ports &uart_tx_ports, streaming chanend cRxUart, s_multi_uart_rx_ports &uart_rx_ports, in port uart_ext_clk_pin, clock uart_clock);

#endif /* __MULTI_UART_RXTX_H__ */
