#include "telnet_to_uart.h"
#include "s2e_conf.h"
#include "s2e_def.h"
#include "xc_ptr.h"
#include "telnet.h"
#include <safestring.h>

typedef struct uart_channel_info {
  char uart_tx_buffer[UIP_CONF_RECEIVE_WINDOW];
  char uart_rx_buffer[2][UART_RX_MAX_PACKET_SIZE];
  int current_rx_buffer;
  int current_rx_buffer_length;
  int conn_id;
  int ip_port;
  int sending_welcome;
  int parse_state;
} uart_channel_info;

static char welcome_msg[] =
  "Welcome to serial to ethernet telnet server demo!\n(This server config acts as echo server...)\n";

static uart_channel_info uart_channel_state[NUM_UART_CHANNELS];

int telnet_to_uart_get_port(int id)
{
  return uart_channel_state[id].ip_port;
}

void telnet_to_uart_init(chanend c_xtcp, chanend c_uart_data)
{
  for (int i=0;i<NUM_UART_CHANNELS;i++) {
    uart_channel_state[i].current_rx_buffer = -1;
    uart_channel_state[i].conn_id = -1;
    uart_channel_state[i].ip_port = TELNET_UART_BASE_PORT + i;

    c_uart_data <: array_to_xc_ptr(uart_channel_state[i].uart_tx_buffer);

    c_uart_data <: array_to_xc_ptr(uart_channel_state[i].uart_rx_buffer[0]);
    c_uart_data <: array_to_xc_ptr(uart_channel_state[i].uart_rx_buffer[1]);

    xtcp_listen(c_xtcp, uart_channel_state[i].ip_port, XTCP_PROTOCOL_TCP);
  }
}

static int get_uart_id_from_port(int p) {
  if (p == -1)
    return -1;

  for (int i=0;i<NUM_UART_CHANNELS;i++) {
    if (p == uart_channel_state[i].ip_port)
        return i;
  }
  return -1;
}

static int get_conn_id_from_uart_id(int i) {
  if (i == -1)
    return -1;
  return uart_channel_state[i].conn_id;
}

void telnet_to_uart_event_handler(chanend c_xtcp,
                                  chanend c_uart_data,
                                  xtcp_connection_t &conn)
{
  int uart_id, len, close_request;

  switch (conn.event)
    {
    case XTCP_IFUP:
    case XTCP_IFDOWN:
    case XTCP_ALREADY_HANDLED:
      return;
    default:
      break;
    }

  uart_id = get_uart_id_from_port(conn.local_port);

  if (uart_id != -1) {
    switch (conn.event)
      {
      case XTCP_NEW_CONNECTION:
        uart_channel_state[uart_id].conn_id = conn.id;
        uart_channel_state[uart_id].sending_welcome = 1;
        init_telnet_parse_state(uart_channel_state[uart_id].parse_state);
        xtcp_ack_recv_mode(c_xtcp, conn);
        xtcp_init_send(c_xtcp, conn);
        break;
      case XTCP_RECV_DATA:
        len = xtcp_recv(c_xtcp, uart_channel_state[uart_id].uart_tx_buffer);
        len = parse_telnet_buffer(uart_channel_state[uart_id].uart_tx_buffer,
                                  len,
                                  uart_channel_state[uart_id].parse_state,
                                  close_request);
        if (close_request)
          xtcp_close(c_xtcp, conn);
        mutual_comm_initiate(c_uart_data);
        c_uart_data <: NEW_UART_TX_DATA;
        c_uart_data <: uart_id;
        c_uart_data <: len;
        break;
      case XTCP_REQUEST_DATA:
      case XTCP_SENT_DATA:
        if (uart_channel_state[uart_id].sending_welcome &&
            conn.event != XTCP_SENT_DATA) {
          xtcp_send(c_xtcp, welcome_msg, sizeof(welcome_msg));
        }
        else {
          uart_channel_state[uart_id].sending_welcome = 0;
          mutual_comm_initiate(c_uart_data);
          c_uart_data <: GET_UART_RX_DATA_TO_SEND;
          c_uart_data <: uart_id;
          c_uart_data :> uart_channel_state[uart_id].current_rx_buffer;
          c_uart_data :> uart_channel_state[uart_id].current_rx_buffer_length;
          if (uart_channel_state[uart_id].current_rx_buffer == -1)
            xtcp_complete_send(c_xtcp);
          else
            xtcp_send(c_xtcp,
                      uart_channel_state[uart_id].uart_rx_buffer[uart_channel_state[uart_id].current_rx_buffer],
                      uart_channel_state[uart_id].current_rx_buffer_length);
        }
        break;
      case XTCP_RESEND_DATA:
        if (uart_channel_state[uart_id].sending_welcome) {
          xtcp_send(c_xtcp, welcome_msg, sizeof(welcome_msg));
        } else {
          xtcp_send(c_xtcp,
                    uart_channel_state[uart_id].uart_rx_buffer[uart_channel_state[uart_id].current_rx_buffer],
                    uart_channel_state[uart_id].current_rx_buffer_length);
        }
        break;
      case XTCP_CLOSED:
      case XTCP_ABORTED:
        uart_channel_state[uart_id].conn_id = -1;
        uart_channel_state[uart_id].current_rx_buffer = -1;
        break;
    }
    conn.event = XTCP_ALREADY_HANDLED;
  }
}

static void handle_notification(chanend c_xtcp,
                                chanend c_uart_data)
{
  int cmd, uart_id=0;
  xtcp_connection_t conn;

  while (uart_id != -1) {
    c_uart_data :> cmd;
    c_uart_data :> uart_id;

    conn.id = get_conn_id_from_uart_id(uart_id);

    if (conn.id != -1) {
      switch (cmd)
        {
        case SENT_UART_TX_DATA:
          xtcp_ack_recv(c_xtcp, conn);
          break;
        case UART_RX_DATA_READY:
          xtcp_init_send(c_xtcp, conn);
          break;
        }
    }
  }

}



select telnet_to_uart_notification_handler(chanend c_xtcp,
                                           chanend c_uart_data)
{
 case mutual_comm_notified(c_uart_data):
   handle_notification(c_xtcp, c_uart_data);
   break;
}


