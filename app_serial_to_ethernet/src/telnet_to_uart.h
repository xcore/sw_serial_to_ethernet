#ifndef __TELNET_TO_UART_H__
#define __TELNET_TO_UART_H__
#include "xccompat.h"
#include "xtcp_client.h"
#include "mutual_thread_comm.h"
#include "s2e_conf.h"

/**
 * This function initializes UART state structure, assigns configured/default
 * telnet ports and listens on these ports, shares UART buffer references
 * to UART handler thread
 * @param     c_xtcp        Channel-end between XTCP and TCP handler thread
 * @param     c_uart_data   Channel-end to communicate UART data between
 *             TCP handler and UART handler thread
 * @param     telnet_port_address  Array contining telnet ports mapped
 *             for configured UARTs
 * @return              None
 */
void telnet_to_uart_init(chanend c_xtcp,
                         chanend c_uart_data,
                         int telnet_port_address[]);

/**
 * This function handles XTCP events related to Telnet data communication.
 * For any event, a correponding UART is mapped from XTCP connection
 * As a part of event handling, this function does the following:
 * (i) for new connections, TCP connection details are stored and telnet
 * parse state machine and TCP ack mode is initialized
 * (ii) for recieve events, data from TCP stack is collected into appropriate
 * UART buffers. Received data is sent to telnet parser server in order to
 * separate application data from telnet protocol. Initiates UART data
 * transaction on c_uart_data channel in order to send data to UART
 * (iii) for send requests initiated by telnet handler, this handler performs
 *  either of the following functionality
 *  (a) welcome messages are sent to respective telnet clients at the start of
 *  each session
 *  (b) collect outstanding data from appropriate UART RX active buffer and
 *  sends on XTCP connection
 * @param     c_xtcp      Channel-end between XTCP and TCP handler thread
 * @param     c_uart_data Channel-end to communicate UART data between
 *             TCP handler and UART handler thread
 * @param     conn        Reference to structure holding IP configuration info
 * @return              None
 */
void telnet_to_uart_event_handler(chanend c_xtcp,
                chanend c_uart_data,
                REFERENCE_PARAM(xtcp_connection_t, conn));

#ifdef __XC__
select telnet_to_uart_notification_handler(chanend c_xtcp, chanend c_uart_data);
#endif

int telnet_to_uart_get_port(int id);

void telnet_to_uart_set_port(chanend c_xtcp, int id, int telnet_port);

int telnet_to_uart_port_used_elsewhere(int id, int telnet_port);

#endif // __TELNET_TO_UART_H__
