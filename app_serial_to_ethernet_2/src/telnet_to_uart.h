#ifndef __TELNET_TO_UART_H__
#define __TELNET_TO_UART_H__
#include "xccompat.h"
#include "xtcp_client.h"
#include "mutual_thread_comm.h"
#include "s2e_conf.h"

typedef struct uart_channel_state_t {
  char uart_tx_buffer[UIP_CONF_RECEIVE_WINDOW];
  char uart_rx_buffer[2][UART_RX_MAX_PACKET_SIZE];
  int current_rx_buffer;
  int current_rx_buffer_length;
  int conn_id;
  int ip_port;
  int sending_welcome;
  int sending_data;
  int parse_state;
} uart_channel_state_t;




void telnet_to_uart_init(chanend c_xtcp, chanend c_uart_data);

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

