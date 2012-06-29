#include <stdlib.h>

#include "telnet_config.h"
#include "telnet.h"
#include "telnet_to_uart.h"
#include "uart_handler.h"
#include "s2e_conf.h"
#include "s2e_flash.h"
#include "s2e_def.h"
#include "xtcp_client.h"
#include "mutual_thread_comm.h"
#include "string.h"
#include "itoa.h"
#include "s2e_validation.h"


#define TELNET_CONFIG_NUM_CONNECTIONS 1

typedef enum {
  TELNET_CONFIG_CMD_GET=1,
  TELNET_CONFIG_CMD_SET=2,
  TELNET_CONFIG_CMD_SAVE=3,
  TELNET_CONFIG_CMD_RESTORE=4,
} telnet_config_cmd_t;

typedef enum {
  PARSING_SEP,
  PARSING_VALUE
} telnet_config_parsing_state0_t;

typedef enum {
  PARSING_START,
  PARSING_CMD,
  PARSING_ID,
  PARSING_PARITY,
  PARSING_STOP_BITS,
  PARSING_BAUD,
  PARSING_CHAR_LEN,
  PARSING_TELNET_PORT,
  PARSING_TERM
} telnet_config_parsing_state1_t;

#define MAX_VALUE_LEN 10

typedef struct connection_state_t {
  int conn_id;
  int active;
  telnet_config_cmd_t cmd;
  telnet_config_cmd_t cmd_out;
  uart_config_data_t config_in;
  uart_config_data_t config_out;
  int telnet_port_in;
  int telnet_port_out;
  int telnet_parsing_state;
  telnet_config_parsing_state0_t config_parsing_state0;
  telnet_config_parsing_state1_t config_parsing_state1;
  int sending_welcome;
  int sending_ack;
  char *err;
  char buf[MAX_VALUE_LEN+1];
  int buf_len;
} connection_state_t;

static char buf[UIP_CONF_RECEIVE_WINDOW];

static char welcome_msg[] =
  "Welcome to serial to ethernet telnet server demo!\nThis is the configuration server\n";

static char invalid_cmd_msg[] = "Invalid command";
static char flash_err_msg[] = "Flash error";

static connection_state_t telnet_config_states[TELNET_CONFIG_NUM_CONNECTIONS];

void telnet_config_init(chanend c_xtcp) {
  for (int i=0;i<TELNET_CONFIG_NUM_CONNECTIONS;i++) {
    telnet_config_states[i].active = 0;
  }
  xtcp_listen(c_xtcp, S2E_TELNET_CONFIG_PORT, XTCP_PROTOCOL_TCP);
}

static connection_state_t *get_new_state()
{
  for (int i=0;i<TELNET_CONFIG_NUM_CONNECTIONS;i++) {
    if (!telnet_config_states[i].active) {
      telnet_config_states[i].active = 1;
      return &telnet_config_states[i];
    }
  }
  return NULL;
}

static connection_state_t *get_state_from_connection(xtcp_connection_t *conn)
{
  for (int i=0;i<TELNET_CONFIG_NUM_CONNECTIONS;i++) {
    if (telnet_config_states[i].active &&
        telnet_config_states[i].conn_id == conn->id) {
      return &telnet_config_states[i];
    }
  }
  return NULL;
}

static void reset_parsing_state(connection_state_t *st)
{
  st->config_parsing_state0 = PARSING_VALUE;
  st->config_parsing_state1 = PARSING_START;
  st->buf_len = 0;
}

static void store_value(connection_state_t *st)
{
  st->buf[st->buf_len] = 0;
  int val = atoi(st->buf);

  switch (st->config_parsing_state1)
    {
    case PARSING_START:
      break;
    case PARSING_CMD:
      st->cmd = val;
      break;
    case PARSING_ID:
      st->config_in.channel_id = val;
      break;
    case PARSING_PARITY:
      st->config_in.parity = val;
      break;
    case PARSING_STOP_BITS:
      st->config_in.stop_bits = val;
      break;
    case PARSING_BAUD:
      st->config_in.baud = val;
      break;
    case PARSING_CHAR_LEN:
      st->config_in.char_len = val;
      break;
    case PARSING_TELNET_PORT:
      st->telnet_port_in = val;
      break;
    case PARSING_TERM:
      // should not get here
      break;
    }

  if (st->cmd == TELNET_CONFIG_CMD_GET &&
      st->config_parsing_state1 == PARSING_ID)  {
    st->config_parsing_state1 = PARSING_TERM;
  }
  else if (st->config_parsing_state1 == PARSING_CMD &&
      st->cmd  >= 3)
    st->config_parsing_state1 = PARSING_TERM;
  else
    st->config_parsing_state1++;

}

static void execute_command(chanend c_xtcp,
                            chanend c_uart_config,
                            chanend c_flash_data,
                            xtcp_connection_t *conn,
                            connection_state_t *st)
{
  int out_channel_id;
  int flash_result;
  uart_config_data_t data1;
  int telnet_port1;

  switch (st->cmd)
    {
    case TELNET_CONFIG_CMD_SET:
      st->err = s2e_validate_uart_config(&st->config_in);
      if (st->err) {
        xtcp_init_send(c_xtcp, conn);
        return;
      }

      st->err = s2e_validate_telnet_port(st->config_in.channel_id,
                                         st->telnet_port_in);
      if (st->err) {
        xtcp_init_send(c_xtcp, conn);
        return;
      }

      uart_config_data_t *config = uart_get_config(st->config_in.channel_id);
      *config = st->config_in;
      uart_set_config(c_uart_config, &st->config_in);
      telnet_to_uart_set_port(c_xtcp,
                              st->config_in.channel_id,
                              st->telnet_port_in);

      out_channel_id = st->config_in.channel_id;
      break;
    case TELNET_CONFIG_CMD_GET:
      st->err = s2e_validate_channel_id(st->config_in.channel_id);
      if (st->err) {
        xtcp_init_send(c_xtcp, conn);
        return;
      }
      out_channel_id = st->config_in.channel_id;
      break;
    case TELNET_CONFIG_CMD_SAVE:
        // Received Save request from web page
        send_cmd_to_flash_thread(c_flash_data, UART_CONFIG, FLASH_CMD_SAVE);

        for(int i = 0; i < NUM_UART_CHANNELS; i++)
        {
            uart_config_data_t *data1 = uart_get_config(i);
            send_data_to_flash_thread(c_flash_data, data1);
        }

        flash_result = get_flash_access_result(c_flash_data);

        if (flash_result != S2E_FLASH_OK)
        {
            st->err = flash_err_msg;
            xtcp_init_send(c_xtcp, conn);
            return;
        }
        out_channel_id = 7;
        break;

    case TELNET_CONFIG_CMD_RESTORE:
        // Received Restore request from web page
        send_cmd_to_flash_thread(c_flash_data, UART_CONFIG, FLASH_CMD_RESTORE);
        flash_result = get_flash_access_result(c_flash_data);

        if (flash_result == S2E_FLASH_OK)
        {
            for (int i = 0; i < NUM_UART_CHANNELS; i++)
            {
                get_data_from_flash_thread(c_flash_data, &data1, &telnet_port1);
                uart_config_data_t *config = uart_get_config(data1.channel_id);
                *config = data1;
                uart_set_config(c_uart_config, &data1);
                telnet_to_uart_set_port(c_xtcp, data1.channel_id, telnet_port1);
            }
        }
        else
        {
            st->err = flash_err_msg;
            xtcp_init_send(c_xtcp, conn);
            return;
        }

        out_channel_id = 7;
        break;

    default:
      st->err = invalid_cmd_msg;
      xtcp_init_send(c_xtcp, conn);
      return;
      break;
  }
  st->config_out = *uart_get_config(out_channel_id);
  st->telnet_port_out = telnet_to_uart_get_port(out_channel_id);
  st->cmd_out = st->cmd;
  st->sending_ack = 1;
  xtcp_init_send(c_xtcp, conn);
}

static void parse_config(chanend c_xtcp,
                         chanend c_uart_config,
                         chanend c_flash_data,
                         xtcp_connection_t *conn,
                         char *buf,
                         int len,
                         connection_state_t *st)
{
  char *end = buf + len;
  while (buf < end) {
    if (st->config_parsing_state0 == PARSING_SEP) {
      if (*buf=='~') {
        buf++;
        continue;
      }
      else {
        st->config_parsing_state0 = PARSING_VALUE;
        st->buf_len = 0;
        continue;
      }
    }
    switch (*buf)
      {
      case '~':
        if (st->config_parsing_state1 == PARSING_TERM) {
          st->err = invalid_cmd_msg;
          xtcp_init_send(c_xtcp, conn);
          reset_parsing_state(st);
        } else {
          store_value(st);
          st->config_parsing_state0 = PARSING_SEP;
          buf++;
        }
        break;
      case '@':
        if (st->config_parsing_state1 == PARSING_TERM) {
          execute_command(c_xtcp, c_uart_config, c_flash_data, conn, st);
          reset_parsing_state(st);
        }
        else {
          st->err = invalid_cmd_msg;
          xtcp_init_send(c_xtcp, conn);
          reset_parsing_state(st);
        }
        buf++;
        break;
      case 10:
      case 13:
        // Newline resets everything
        reset_parsing_state(st);
        buf++;
        break;
      default:
        if (st->buf_len < MAX_VALUE_LEN) {
          st->buf[st->buf_len] = *buf;
          st->buf_len++;
        }
        buf++;
        break;
      }

  }
}

static char * add_sep(char *buf, int n) {
  for (int i=0;i<n;i++)
    *buf++ = '~';
  return buf;
}

static int construct_ack(connection_state_t *st,
                         char *buf)
{
  char *buf0 = buf;
  buf = add_sep(buf, 1);
  buf += itoa(st->cmd_out, buf, 10, 1);
  buf = add_sep(buf, 2);
  buf += itoa(st->config_out.channel_id, buf, 10, 1);
  buf = add_sep(buf, 2);
  buf += itoa(st->config_out.parity, buf, 10, 1);
  buf = add_sep(buf, 2);
  buf += itoa(st->config_out.stop_bits, buf, 10, 1);
  buf = add_sep(buf, 2);
  buf += itoa(st->config_out.baud, buf, 10, 1);
  buf = add_sep(buf, 2);
  buf += itoa(st->config_out.char_len, buf, 10, 1);
  buf = add_sep(buf, 2);
  buf += itoa(st->telnet_port_out, buf, 10, 1);
  buf = add_sep(buf, 1);
  *buf++ = '@';
  *buf++ = '\n';
  return (buf-buf0);
}

void telnet_config_event_handler(chanend c_xtcp,
                                 chanend c_uart_config,
                                 chanend c_flash_data,
                                 xtcp_connection_t *conn)
{

  switch (conn->event)
    {
    case XTCP_IFUP:
    case XTCP_IFDOWN:
    case XTCP_ALREADY_HANDLED:
      return;
    default:
      break;
    }


  if (conn->local_port == S2E_TELNET_CONFIG_PORT) {
    connection_state_t *st = get_state_from_connection(conn);
    int close_request;
    int len;
    switch (conn->event)
      {
      case XTCP_NEW_CONNECTION:
        st = get_new_state();
        if (!st) {
          xtcp_abort(c_xtcp, conn);
          break;
        }
        st->sending_welcome = 1;
        st->sending_ack = 0;
        st->err = NULL;
        st->conn_id = conn->id;
        init_telnet_parse_state(&st->telnet_parsing_state);
        reset_parsing_state(st);
        xtcp_init_send(c_xtcp, conn);
        break;
      case XTCP_RECV_DATA:
        len = xtcp_recv(c_xtcp, buf);
        if (!st || !st->active)
          break;

        len = parse_telnet_buffer(buf,
                                  len,
                                  &st->telnet_parsing_state,
                                  &close_request);
        parse_config(c_xtcp, c_uart_config, c_flash_data, conn, buf, len, st);
        if (close_request)
          xtcp_close(c_xtcp, conn);
        break;
      case XTCP_REQUEST_DATA:
      case XTCP_RESEND_DATA:
        if (!st || !st->active) {
          xtcp_complete_send(c_xtcp);
          break;
        }

        // When sending either st->sending_welcome is true,
        // st->sending_ack is true or st->err is non null. Depending on
        // whether the connection is sending a welcome message, ack or
        // error message

        if (st->sending_welcome) {
          xtcp_send(c_xtcp, welcome_msg, sizeof(welcome_msg));
        }
        else if (st->sending_ack) {
          int len = construct_ack(st, buf);
          xtcp_send(c_xtcp, buf, len);
        }
        else if (st->err) {
          int len = strlen(st->err);
          strcpy(buf, st->err);
          buf[len] = '\n';
          xtcp_send(c_xtcp, buf, len+1);
        }
        else {
          xtcp_complete_send(c_xtcp);
        }
        break;
      case XTCP_SENT_DATA:
        xtcp_complete_send(c_xtcp);
        if (st) {
          st->sending_ack = 0;
          st->sending_welcome = 0;
          st->err = NULL;
        }
        break;
      case XTCP_CLOSED:
      case XTCP_ABORTED:
      case XTCP_TIMED_OUT:
        if (st) {
          st->active = 0;
        }
        break;
      default:
        break;
    }
    conn->event = XTCP_ALREADY_HANDLED;
  }

}
