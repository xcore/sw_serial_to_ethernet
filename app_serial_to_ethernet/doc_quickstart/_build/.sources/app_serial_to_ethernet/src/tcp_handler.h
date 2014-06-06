#ifndef __TCP_HANDLER_H__
#define __TCP_HANDLER_H__

#ifdef __XC__
/**
 * This function handles TCP handler thread.
 * During initialization, IP configuration details stored in flash
 * are retrieved from UDP discovery function and passed on to ETH thread
 * This thread mainly handles
 * (a) all XTCP events and invokes respective sub-function handlers
 * (b) notification messages from UART handler thread for UART data
 * transactions
 * @param     c_xtcp        Channel-end between XTCP and TCP handler thread
 * @param     c_uart_data   Channel-end to communicate UART data between
 *             TCP handler and UART handler thread
 * @param     c_uart_config Channel-end to communicate UART configuration data
 *             TCP handler and UART handler thread
 * @param     c_flash_web   Channel-end to communicate Web page data stored in
 *             flash to TCP handler thread
 * @param     c_flash_data  Channel-end to communicate UART configuration data
 *              stored in flash to TCP handler thread
 * @return              None
 */
void tcp_handler(chanend c_xtcp,
                 chanend c_uart_data,
                 chanend c_uart_config,
                 chanend ?c_flash_web,
                 chanend ?c_flash_data);
#endif

#endif // __TCP_HANDLER_H__

