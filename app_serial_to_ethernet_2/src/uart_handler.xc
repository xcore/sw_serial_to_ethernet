#include "xs1.h"
#include "uart_handler.h"
#include "mutual_thread_comm.h"
#include "s2e_conf.h"
#include "s2e_def.h"
#include "xc_ptr.h"
#include "multi_uart_rx.h"
#include "multi_uart_tx.h"
#include "print.h"

typedef enum uart_config_cmd_t {
  UART_HANDLER_GET_UART_CONFIG,
  UART_HANDLER_SET_UART_CONFIG,
} uart_config_cmd_t;

typedef struct uart_tx_info {
  int len;
  int i;
  xc_ptr buffer;
} uart_tx_info;

typedef struct uart_rx_info {
  xc_ptr buffer[2];
  int current_buffer;
  int current_buffer_len;
  int notified;
  int timestamp;
} uart_rx_info;

#define UART_HANDLER_PERIODIC_TIME 1000
#define UART_RX_FLUSH_DELAY 2000000

static uart_tx_info uart_tx_state[NUM_UART_CHANNELS];
static uart_rx_info uart_rx_state[NUM_UART_CHANNELS];

static uart_config_data_t uart_config[NUM_UART_CHANNELS];


void uart_get_config(chanend c_uart_config,
                     uart_config_data_t &data)
{
  c_uart_config <: UART_HANDLER_GET_UART_CONFIG;
  c_uart_config <: data.channel_id;
  c_uart_config :> data;
}

void uart_set_config(chanend c_uart_config,
                     uart_config_data_t &data)
{
  c_uart_config <: UART_HANDLER_SET_UART_CONFIG;
  c_uart_config <: data.channel_id;
  c_uart_config <: data;
}

#pragma unsafe arrays
static void push_to_uart_rx_buffer(uart_rx_info &st,
                                   unsigned uart_char,
                                   chanend c_uart_data,
                                   mutual_comm_state_t &mstate)
{
  if (st.current_buffer_len < UART_RX_MAX_PACKET_SIZE) {
    timer tmr;
    tmr :> st.timestamp;
    write_byte_via_xc_ptr_indexed(st.buffer[st.current_buffer],
                                  st.current_buffer_len,
                                  uart_char);
    st.current_buffer_len += 1;
    if (!st.notified &&
        st.current_buffer_len >= UART_RX_MIN_PACKET_SIZE)
      {
      mutual_comm_notify(c_uart_data, mstate);
      }
  } else {
#ifdef S2E_DEBUG_OVERFLOW
    // Drop data due to buffer overflow
    printchar('!');
#endif

  }

  return;
}

static void tx_send_data(streaming chanend c_uart_tx,
                         chanend c_uart_data,
                         mutual_comm_state_t &mstate,
                         uart_tx_info &st,
                         int uart_id)
{
  if (st.i < st.len) {
    int buffer_full;
    int datum;

    read_byte_via_xc_ptr_indexed(datum, st.buffer,st.i);

    buffer_full = uart_tx_put_char(uart_id, datum);
    if (buffer_full==0) {
      st.i += 1;
      if (st.i == st.len)
        mutual_comm_notify(c_uart_data, mstate);
    }
  }
}

static int flush_rx_buffer(uart_rx_info &st)
{
  timer tmr;
  int now;
  tmr :> now;

  if (st.current_buffer_len >= UART_RX_MIN_PACKET_SIZE)
    return 1;

  if (st.current_buffer_len > 0 &&
      ((now - st.timestamp) > UART_RX_FLUSH_DELAY))
    return 1;

  return 0;
}

static void tx_notify_tcp_handler(chanend c_uart_data,
                                  uart_tx_info &st,
                                  int uart_id)
{
  if (st.len != 0 && st.i == st.len) {
    c_uart_data <: SENT_UART_TX_DATA;
    c_uart_data <: uart_id;
    st.i = 0;
    st.len = 0;
  }
}

static void rx_notify_tcp_handler(chanend c_uart_data,
                                  uart_rx_info &st,
                                  int uart_id)
{
  if (!st.notified && flush_rx_buffer(st))
    {
      int is_inflight;
      c_uart_data <: UART_RX_DATA_READY;
      c_uart_data <: uart_id;
      c_uart_data :> is_inflight;
      if (is_inflight)
        st.notified = 1;
      else {
        // The other side has dumped the data
        st.current_buffer_len = 0;
      }
    }
}


#pragma unsafe arrays
static void uart_configure_tx_channel(int i)
{
  uart_tx_initialise_channel(i,
                             uart_config[i].parity,
                             uart_config[i].stop_bits,
                             uart_config[i].polarity,
                             uart_config[i].baud,
                             uart_config[i].char_len);
}

#pragma unsafe arrays
static void uart_configure_rx_channel(int i)
{
  uart_rx_initialise_channel(i,
                             uart_config[i].parity,
                             uart_config[i].stop_bits,
                             uart_config[i].polarity,
                             uart_config[i].baud,
                             uart_config[i].char_len);
}

#pragma unsafe arrays
void uart_handler(chanend c_uart_data,
                  chanend c_uart_config,
                 streaming chanend c_uart_rx,
                 streaming chanend c_uart_tx)
{
  timer tmr;
  int periodic_timeout;
  mutual_comm_state_t mstate;
  char go;
  mutual_comm_init_state(mstate);

  for (int i=0;i<NUM_UART_CHANNELS;i++) {

    uart_config[i].channel_id = i;
    uart_config[i].parity = even;
    uart_config[i].stop_bits = sb_1;
    uart_config[i].baud = 115200;
    uart_config[i].polarity = start_0;
    uart_config[i].char_len = 8;

    c_uart_data :> uart_tx_state[i].buffer;
    uart_tx_state[i].len = 0;
    uart_tx_state[i].i = 0;

    uart_configure_tx_channel(i);

    c_uart_data :> uart_rx_state[i].buffer[0];
    c_uart_data :> uart_rx_state[i].buffer[1];
    uart_rx_state[i].current_buffer = 0;
    uart_rx_state[i].current_buffer_len = 0;
    uart_rx_state[i].notified = 0;

    uart_configure_rx_channel(i);
  }


  do { c_uart_rx :> go; } while (go != MULTI_UART_GO);
  c_uart_rx <: 1;
  do { c_uart_tx :> go; } while (go != MULTI_UART_GO);
  c_uart_tx <: 1;


  tmr :> periodic_timeout;
  periodic_timeout += UART_HANDLER_PERIODIC_TIME;

  while (1) {
    int is_data_request;
    #pragma ordered
    select
      {
      case c_uart_rx :> char channel_id:
        { unsigned uart_char;
          uart_char = (unsigned) uart_rx_grab_char(channel_id);
          if(uart_rx_validate_char(channel_id, uart_char) == 0) {
            #ifdef S2E_DEBUG_BROADCAST_UART_0
              // In this debug mode the data from uart 0 is sent to
              // all connections
              if (channel_id == 0) {
                for (int i=0;i<NUM_UART_CHANNELS;i++)
                  push_to_uart_rx_buffer(uart_rx_state[(int) i],
                                         uart_char,
                                         c_uart_data,
                                         mstate);
              }
              else {
                // Drop anything coming in on the other serial ports
              }
            #else
              push_to_uart_rx_buffer(uart_rx_state[(int) channel_id],
                                     uart_char,
                                     c_uart_data,
                                     mstate);
            #endif
          }
        }
        break;
      case mutual_comm_transaction(c_uart_data,
                                   is_data_request,
                                   mstate):
        if (is_data_request) {
          for (int i=0;i<NUM_UART_CHANNELS;i++) {
            rx_notify_tcp_handler(c_uart_data, uart_rx_state[i], i);
            tx_notify_tcp_handler(c_uart_data, uart_tx_state[i], i);
          }
          c_uart_data <: -1;
          c_uart_data <: -1;
        } else {
          int cmd, uart_id;
          c_uart_data :> cmd;
          c_uart_data :> uart_id;
          switch (cmd) {
          case NEW_UART_TX_DATA:
            c_uart_data :> uart_tx_state[uart_id].len;
            break;
          case GET_UART_RX_DATA_TO_SEND:
            if (flush_rx_buffer(uart_rx_state[uart_id])) {
              int len = uart_rx_state[uart_id].current_buffer_len;
              xc_ptr buf = uart_rx_state[uart_id].current_buffer;
              c_uart_data <: buf;
              c_uart_data <: len;

              #ifdef S2E_DEBUG_WATERMARK_UNUSED_BUFFER_AREA
              for (int i=len;i<UART_RX_MAX_PACKET_SIZE;i++) {
                write_byte_via_xc_ptr_indexed(buf, i, 'A');
              }
              #endif

              uart_rx_state[uart_id].current_buffer =
                1 - uart_rx_state[uart_id].current_buffer;

              #ifdef S2E_DEBUG_WATERMARK_UNUSED_BUFFER_AREA
              buf = uart_rx_state[uart_id].current_buffer;
              for (int i=0;i<UART_RX_MAX_PACKET_SIZE;i++)
                write_byte_via_xc_ptr_indexed(buf, i, 'B');
              #endif


              uart_rx_state[uart_id].current_buffer_len = 0;
              uart_rx_state[uart_id].notified = 0;
            } else {
              c_uart_data <: -1;
              c_uart_data <: -1;
            }
            break;
          }
        }
        mutual_comm_complete_transaction(c_uart_data,
                                         is_data_request,
                                         mstate);
        break;
      case c_uart_config :> int cmd:
        switch (cmd)
          {
          case UART_HANDLER_SET_UART_CONFIG: {
            int id;
            timer tmr;
            c_uart_config :> id;
            c_uart_config :> uart_config[id];
            uart_tx_reconf_pause(c_uart_tx, tmr);
            uart_rx_reconf_pause(c_uart_rx);
            uart_configure_rx_channel(id);
            uart_configure_tx_channel(id);
            uart_tx_reconf_enable(c_uart_tx);
            uart_rx_reconf_enable(c_uart_rx);
            }
            break;
          case UART_HANDLER_GET_UART_CONFIG: {
            int id;
            c_uart_config :> id;
            c_uart_config <: uart_config[id];
            }
            break;
        }
        break;
      case tmr when timerafter(periodic_timeout) :> void:
        periodic_timeout += UART_HANDLER_PERIODIC_TIME;
        for (int i=0;i<NUM_UART_CHANNELS;i++) {
          tx_send_data(c_uart_tx,
                       c_uart_data,mstate,
                       uart_tx_state[i],
                       i);
        }
        for (int i=0;i<NUM_UART_CHANNELS;i++)
          if (!uart_rx_state[i].notified && flush_rx_buffer(uart_rx_state[i]))
            mutual_comm_notify(c_uart_data,mstate);
        break;
      }
  }



}

