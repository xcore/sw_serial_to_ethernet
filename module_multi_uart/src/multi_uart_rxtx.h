#ifndef __MULTI_UART_RXTX_H__
#define __MULTI_UART_RXTX_H__

#include "multi_uart_tx.h"
#include "multi_uart_rx.h"

/**
 * Configure and run the Multi-UART TX & RX server threads using an external clock for TX
 * @param   cTxUart             TX Server Channel
 * @param   uart_tx_ports       TX Ports structure (reference parameter)
 * @param   cRxUart             RX Server Channel
 * @param   uart_rx_ports       RX Ports structure (reference parameter)
 * @param   uart_clock_rx       Clock block to run the RX port from
 * @param   uart_ext_clk_pin    External clock reference input pin
 * @param   uart_clock_tx       Clock block to run the TX port from
 */
#ifdef __XC__
void run_multi_uart_rxtx( streaming chanend cTxUart, REFERENCE_PARAM(s_multi_uart_tx_ports, uart_tx_ports), streaming chanend cRxUart, REFERENCE_PARAM(s_multi_uart_rx_ports, uart_rx_ports), clock uart_clock_rx, in port uart_ext_clk_pin, clock uart_clock_tx);
#else
void run_multi_uart_rxtx( streaming chanend cTxUart, REFERENCE_PARAM(s_multi_uart_tx_ports, uart_tx_ports), streaming chanend cRxUart, REFERENCE_PARAM(s_multi_uart_rx_ports, uart_rx_ports), clock uart_clock_rx, unsigned uart_ext_clk_pin, clock uart_clock_tx);
#endif

/**
 * Configure and run the Multi-UART TX & RX server threads using internal clocks for TX & RX
 * @param   cTxUart             TX Server Channel
 * @param   uart_tx_ports       TX Ports structure
 * @param   cRxUart             RX Server Channel
 * @param   uart_rx_ports       RX Ports structure
 * @param   uart_clock_rx       Clock block to run the RX port from
 * @param   uart_clock_tx       Clock block to run the TX port from
 */
#ifdef __XC__
void run_multi_uart_rxtx_int_clk( streaming chanend cTxUart, REFERENCE_PARAM(s_multi_uart_tx_ports, uart_tx_ports), streaming chanend cRxUart, REFERENCE_PARAM(s_multi_uart_rx_ports, uart_rx_ports), clock uart_clock_rx, clock uart_clock_tx);
#else
void run_multi_uart_rxtx_int_clk( streaming chanend cTxUart, REFERENCE_PARAM(s_multi_uart_tx_ports, uart_tx_ports), streaming chanend cRxUart, REFERENCE_PARAM(s_multi_uart_rx_ports, uart_rx_ports), clock uart_clock_rx, clock uart_clock_tx);
#endif

#endif /* __MULTI_UART_RXTX_H__ */
