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
 * @param     c_xtcp        Channel between XTCP and TCP handler thread
 * @param     c_uart_data  Channel to communicate UART data between
 *             XTCP and TCP handler thread
 * @param     telnet_port_address  Array contining telnet ports mapped
 *             for configured UARTs
 * @return              None
 */
void telnet_to_uart_init(chanend c_xtcp,
                         chanend c_uart_data,
                         int telnet_port_address[]);

/**
 * This function handles XTCP events related to Telnet data communication.
 * As a part of event handling, this function does the following:
 * (i) for new connections, TCP connection details are stored and telnet
 * parse state machine and TCP ack mode is initialized
 * (ii) for recieve events, data from TCP stack is collected into appropriate
 * UART buffers
 * .
 * .
 * @param     c_xtcp        Channel between XTCP and TCP handler thread
 * @param     c_uart_data   Channel to communicate UART data between
 *             XTCP and TCP handler thread
 * @param     conn          Reference to structure holding IP configuration info
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
