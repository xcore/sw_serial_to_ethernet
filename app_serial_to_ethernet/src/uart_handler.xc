#include "xs1.h"
#include "uart_handler.h"
#include "mutual_thread_comm.h"
#include "s2e_conf.h"
#include "s2e_def.h"
#include "xc_ptr.h"
#include "multi_uart_rx.h"
#include "multi_uart_tx.h"
#include <print.h>

typedef enum uart_config_cmd_t {
  UART_HANDLER_GET_UART_CONFIG,
  UART_HANDLER_SET_UART_CONFIG,
} uart_config_cmd_t;

/**
 * Structure to hold buffer parameters of UART transmit side buffers.
 * UART transmit side buffers contain data collected from Telnet sockets
 * configured for respective UARTs
 */
typedef struct uart_tx_info {
  int len; /**< Depth of buffer (bytes remaining to be transferred to UART) */
  int i; /**< Number of bytes consumed from the buffer */
  int notified; /**< Flag to notify all UART TX data is transferred to MUART component*/
  int sw_fc_out; /**< XMOS device setting its Software fc status to the out connection */
  int sw_fc_in; /**< Software flow control status set by incoming connection */
  xc_ptr buffer; /**< Reference to UART TX buffer */
} uart_tx_info;

/**
 * Structure to hold buffer parameters of UART receive side buffers.
 * UART receive side buffers contain data collected from UARTs
 */
typedef struct uart_rx_info {
  xc_ptr buffer[2]; /**< Reference to UART RX buffer */
  int current_buffer; /**< Refers to active buffer being used from UART RX double buffers */
  int current_buffer_len; /**< Number of bytes (of received UART X data) contained in active buffer */
  int notified; /**< Flag to initiate UART RX data transfer transaction for a UART*/
  int timestamp; /**< Time when UART receive buffer is last updated */
} uart_rx_info;

/**
 * Define time (in clock ticks) to wait before sending the received UART data,
 * when data received is lesser than minimum configured packet size
 */
#define UART_RX_FLUSH_DELAY 20000000

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
  } else {
#ifdef S2E_DEBUG_OVERFLOW
    // Drop data due to buffer overflow
    printchar('!');
#endif
  }
  return;
}

static int tx_sent_all_data(uart_tx_info &st) {
  return (st.len != 0 && st.i == st.len);
}

static void tx_send_data(streaming chanend c_uart_tx,
                         chanend c_uart_data,
                         mutual_comm_state_t &mstate,
                         uart_tx_info &st,
                         int uart_id,
                         int uart_rx_buf_level)
{
    int buffer_full;
    /* Check if RX watermark level has reached; if so, send xon/xoff */
    /*if ((uart_rx_buf_level >= UART_RX_MAX_WATERMARK) && (!st.sw_fc_out)) {
      buffer_full = uart_tx_put_char(uart_id, XOFF);
      if (buffer_full==0) {
        st.sw_fc_out = 1;
      }
    }
    else if ((uart_rx_buf_level < UART_RX_MIN_WATERMARK) && st.sw_fc_out) {*/
#if SW_FC_CTRL
    if ((uart_rx_buf_level < UART_RX_MIN_WATERMARK) && st.sw_fc_out) {
      buffer_full = uart_tx_put_char(uart_id, XON);
      if (buffer_full==0) {
        st.sw_fc_out = 0;
      }
    }
    else if ((st.i < st.len) && (!st.sw_fc_in)) {
#else
    if (st.i < st.len) {
#endif
      int datum;
      read_byte_via_xc_ptr_indexed(datum, st.buffer,st.i);
      buffer_full = uart_tx_put_char(uart_id, datum);
      if (buffer_full==0) {
        st.i += 1;
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
    st.notified = 1;
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
static void uart_configure_tx_channel(int i,
                                      uart_config_data_t &data)
{
  uart_tx_initialise_channel(i,
                             data.parity,
                             data.stop_bits,
                             data.polarity,
                             data.baud,
                             data.char_len);
}

#pragma unsafe arrays
static void uart_configure_rx_channel(int i,
                                      uart_config_data_t &data)
{
  uart_rx_initialise_channel(i,
                             data.parity,
                             data.stop_bits,
                             data.polarity,
                             data.baud,
                             data.char_len);
}

#pragma unsafe arrays
void uart_handler(chanend c_uart_data,
                  chanend c_uart_config,
                 streaming chanend c_uart_rx,
                 streaming chanend c_uart_tx)
{
  mutual_comm_state_t mstate;
  char go;
  int poll_index = 0;
  int tx_notifier = -1, rx_notifier = -1;
  uart_config_data_t config;
  uart_tx_info uart_tx_state[NUM_UART_CHANNELS];
  uart_rx_info uart_rx_state[NUM_UART_CHANNELS];

#ifdef S2E_DEBUG_AUTO_TRAFFIC
  timer tmr;
  int time;
  int i=0,u=0;
  tmr :> time;
#endif

  mutual_comm_init_state(mstate);

  for (int i=0;i<NUM_UART_CHANNELS;i++) {
    c_uart_config :> int cmd;
    c_uart_config :> int id;
    c_uart_config :> config;
    uart_configure_tx_channel(i, config);
    uart_configure_rx_channel(i, config);
  }

  for (int i=0;i<NUM_UART_CHANNELS;i++) {
    c_uart_data :> uart_tx_state[i].buffer;
    uart_tx_state[i].len = 0;
    uart_tx_state[i].i = 0;
    uart_tx_state[i].notified = 0;
    uart_tx_state[i].sw_fc_out = 0;
    uart_tx_state[i].sw_fc_in = 0;

    c_uart_data :> uart_rx_state[i].buffer[0];
    c_uart_data :> uart_rx_state[i].buffer[1];
    uart_rx_state[i].current_buffer = 0;
    uart_rx_state[i].current_buffer_len = 0;
    uart_rx_state[i].notified = 0;
  }


  do { c_uart_rx :> go; } while (go != MULTI_UART_GO);
  c_uart_rx <: 1;
  do { c_uart_tx :> go; } while (go != MULTI_UART_GO);
  c_uart_tx <: 1;

  while (1) {
    int is_data_request;
    #pragma ordered
    select
      {
#ifdef S2E_DEBUG_AUTO_TRAFFIC
      case tmr when timerafter(time) :> int _:
        time += 1200;
        push_to_uart_rx_buffer(uart_rx_state[u],i+48,c_uart_data,mstate);
        u++;
        if (u==8) {
          u=0;
          i+=1;
          if (i>9)
            i=0;
        }
        break;
#endif  //S2E_DEBUG_AUTO_TRAFFIC
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
#else  //S2E_DEBUG_BROADCAST_UART_0
#ifndef S2E_DEBUG_AUTO_TRAFFIC
#if SW_FC_CTRL
              if ((uart_char == XOFF) || (uart_char == XON)) {
                  uart_tx_state[(int) channel_id].sw_fc_in = (uart_char & 0x02) >> 1;
              }
              else {
                  push_to_uart_rx_buffer(uart_rx_state[(int) channel_id],
                                         uart_char,
                                         c_uart_data,
                                         mstate);
              }
#else  //SW_FC_CTRL
              push_to_uart_rx_buffer(uart_rx_state[(int) channel_id],
                                     uart_char,
                                     c_uart_data,
                                     mstate);
#endif  //SW_FC_CTRL
#endif  //S2E_DEBUG_AUTO_TRAFFIC

#if SW_FC_CTRL
              if (uart_rx_state[(int) channel_id].current_buffer_len >= UART_RX_MAX_WATERMARK) {
                if ((!uart_tx_state[(int) channel_id].sw_fc_out) &&
                        (uart_tx_put_char((int) channel_id, XOFF)==0)) {
                  uart_tx_state[(int) channel_id].sw_fc_out = 1;
                }
              }
#endif  //SW_FC_CTRL
#endif  //S2E_DEBUG_BROADCAST_UART_0
          }
        }
        break;
      case mutual_comm_transaction(c_uart_data,
                                   is_data_request,
                                   mstate):
        if (is_data_request) {
          //          for (int i=0;i<NUM_UART_CHANNELS;i++) {
          if (rx_notifier != -1) {
            rx_notify_tcp_handler(c_uart_data, uart_rx_state[rx_notifier],
                                  rx_notifier);
            rx_notifier = -1;
          }
          if (tx_notifier != -1) {
            tx_notify_tcp_handler(c_uart_data, uart_tx_state[tx_notifier],
                                  tx_notifier);
            tx_notifier = -1;
          }
            //          }
          c_uart_data <: -1;
          c_uart_data <: -1;
        } else {
          slave {
            int cmd, uart_id;
            c_uart_data :> cmd;
            c_uart_data :> uart_id;
            switch (cmd)
              {
              case NEW_UART_TX_DATA:
                { int txi;
                  int len;
                  c_uart_data :> txi;
                  c_uart_data :> len;
                  if (txi == 0)
                    uart_tx_state[uart_id].i = 0;
                  uart_tx_state[uart_id].len = txi+len;
                  uart_tx_state[uart_id].notified = 0;
                }
                break;
              case GET_UART_RX_DATA_TO_SEND:
                if (flush_rx_buffer(uart_rx_state[uart_id])) {
                  int len = uart_rx_state[uart_id].current_buffer_len;
                  int cur_buf = uart_rx_state[uart_id].current_buffer;
                  xc_ptr buf = uart_rx_state[uart_id].buffer[cur_buf];
                  c_uart_data <: cur_buf;
                  c_uart_data <: len;

#ifdef S2E_DEBUG_WATERMARK_UNUSED_BUFFER_AREA
                  for (int i=len;i<UART_RX_MAX_PACKET_SIZE;i++) {
                    write_byte_via_xc_ptr_indexed(buf, i, 'A');
                  }
#endif

                  uart_rx_state[uart_id].current_buffer =
                    1 - uart_rx_state[uart_id].current_buffer;

#ifdef S2E_DEBUG_WATERMARK_UNUSED_BUFFER_AREA
                  cur_buf = uart_rx_state[uart_id].current_buffer;
                  buf = uart_rx_state[uart_id].buffer[cur_buf];
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
            c_uart_config :> config;
            uart_tx_reconf_pause(c_uart_tx, tmr);
            uart_rx_reconf_pause(c_uart_rx);
            uart_configure_rx_channel(id, config);
            uart_configure_tx_channel(id, config);
            uart_tx_reconf_enable(c_uart_tx);
            uart_rx_reconf_enable(c_uart_rx);
            }
            break;
        }
        break;
      default:
        tx_send_data(c_uart_tx,
                     c_uart_data,mstate,
                     uart_tx_state[poll_index],
                     poll_index,
                     uart_rx_state[poll_index].current_buffer_len);

        if (tx_notifier == -1 &&
            tx_sent_all_data(uart_tx_state[poll_index]) &&
            !uart_tx_state[poll_index].notified)
          {
            tx_notifier = poll_index;
            mutual_comm_notify(c_uart_data, mstate);
          }

        if (rx_notifier == -1 &&
            !uart_rx_state[poll_index].notified &&
            flush_rx_buffer(uart_rx_state[poll_index])) {
          mutual_comm_notify(c_uart_data,mstate);
          rx_notifier = poll_index;
        }

        poll_index++;
        if (poll_index >= NUM_UART_CHANNELS)
          poll_index = 0;
        break;
      }
  }



}

