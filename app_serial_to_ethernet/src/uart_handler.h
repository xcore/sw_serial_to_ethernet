#ifndef __UART_HANDLER_H__
#define __UART_HANDLER_H__
#include <xccompat.h>
#include "multi_uart_tx.h"
#include "multi_uart_rx.h"
#include "uart_config.h"

#ifdef __XC__
/**
 * This function configures UARTs, initializes application buffers states.
 * As a part of event handling, this function does the following:
 * (i) handles incoming data from UARTs and stores into appropirate buffers
 * (ii) in case of data transfer transaction, either notifies or acknowledges
 *  TCP handler about UART data; otherwise, listens from TCP handler to
 *  (a) collect telnet received data to UART
 *  (b) share appropriate UART buffer holding UART recived data
 * (iii) in case of UART configuration requests, collects appropriate UART
 *  configuration and reconfigures UART for received configuration
 * (iv) sends a data byte from telnet UART buffers in a round robin basis,
 *  and notifies current transmit and receive transactions
 * @param     c_uart_data   Channel-end to communicate UART data between
 *             TCP handler and UART handler thread
 * @param     c_uart_config Channel-end to communicate UART configuration
 *             details between TCP handler and UART handler thread
 * @param     c_uart_rx  Channel primarily to send UART data from
 *             application to MultiUART RX server thread
 * @param     c_uart_tx  Channel primarily to collect UART data from
 *             MultiUART TX server thread into UART handler thread
 * @return              None
 */
void uart_handler(chanend c_uart_data,
                  chanend c_uart_config,
                  streaming chanend c_uart_rx,
                  streaming chanend c_uart_tx);
#endif

void uart_set_config(chanend c_uart_config,
                     REFERENCE_PARAM(uart_config_data_t, data));

#endif // __UART_HANDLER_H__
