#include "s2e_webserver.h"
#include "web_server.h"
#include "uart_handler.h"
#include "s2e_conf.h"
#include "s2e_def.h"
#include "itoa.h"
#include <stdlib.h>
#include <string.h>
#include "print.h"
#include "telnet_to_uart.h"

static uart_config_data_t cached_uart_data;

static char success_msg[] = "<p>Uart configuration set successfully.</p>";

static char bad_parity_msg[] = "<p>Invalid parity setting.</p>";
static char bad_baudrate_msg[] = "<p>Invalid baud rate setting.</p>";
static char bad_stop_bits_msg[] = "<p>Invalid stop bits setting.</p>";
static char bad_char_len_msg[] = "<p>Invalid char length setting.</p>";
static char bad_telnet_port_msg[] = "<p>Invalid telnet port setting.</p>";

static int output_msg(char buf[], const char msg[])
{
  strcpy(buf, msg);
  return strlen(msg);
}

static int get_int_param(const char param[],
                         int connection_state,
                         int *err)
{
  *err = 0;
  char *param_str = web_server_get_param(param, connection_state);

  if (!param_str || !(*param_str)) {*err=1;return 0;}

  return atoi(param_str);
}


int s2e_web_configure(char buf[], int app_state, int connection_state)
{
  int err;
  int val;
  uart_config_data_t data;
  int telnet_port;
  chanend c_uart_config = (chanend) app_state;

  if (!web_server_is_post(connection_state))
    return 0;

  val = get_int_param("id",connection_state,&err);
  if (err)
    return 0;
  data.channel_id = val;


  val = get_int_param("pc",connection_state,&err);
  if (err)
    return output_msg(buf, bad_parity_msg);
  data.parity = val;

  val = get_int_param("sb",connection_state,&err);
  if (err)
    return output_msg(buf, bad_stop_bits_msg);
  data.stop_bits = val;

  val = get_int_param("br",connection_state,&err);
  if (err)
    return output_msg(buf, bad_baudrate_msg);
  data.baud = val;

  val = get_int_param("cl",connection_state,&err);
  if (err)
    return output_msg(buf, bad_char_len_msg);
  data.char_len = val;

  val = get_int_param("tp",connection_state,&err);
  if (err)
    return output_msg(buf, bad_telnet_port_msg);

  telnet_port = val;

  // Do the setting

  uart_set_config(c_uart_config, &data);

  cached_uart_data.channel_id = -1;

  return output_msg(buf, success_msg);
}


static int update_cache(chanend c_uart_config,
                        int connection_state)
{
  char *id_str = web_server_get_param("id",connection_state);

  if (!id_str)
    return -1;

  int id = atoi(id_str);

  if (id < 0 || id > NUM_UART_CHANNELS)
    return -1;

  if (cached_uart_data.channel_id != id) {
    cached_uart_data.channel_id = id;
    uart_get_config(c_uart_config, &cached_uart_data);
  }

  return id;
}

int s2e_web_get_char_len(char buf[], int app_state, int connection_state)
{
  chanend c_uart_config = (chanend) app_state;

  int id = update_cache(c_uart_config, connection_state);
  if (id == -1)
    return 0;

  int len = itoa(cached_uart_data.char_len, buf, 10, 0);
  return len;
}

int s2e_web_get_port(char buf[], int app_state, int connection_state)
{
  chanend c_uart_config = (chanend) app_state;

  int id = update_cache(c_uart_config, connection_state);
  if (id == -1)
    return 0;

  int len = itoa(telnet_to_uart_get_port(id), buf, 10, 0);
  return len;
}

int s2e_web_get_baud(char buf[], int app_state, int connection_state)
{
  chanend c_uart_config = (chanend) app_state;

  int id = update_cache(c_uart_config, connection_state);
  if (id == -1)
    return 0;

  int len = itoa(cached_uart_data.baud, buf, 10, 0);
  return len;
}

int s2e_web_get_parity_selected(char buf[], int app_state, int connection_state,
int parity)
{
  chanend c_uart_config = (chanend) app_state;

  int id = update_cache(c_uart_config, connection_state);
  if (id == -1)
    return 0;

  if (cached_uart_data.parity == parity) {
    char selstr[] = "selected";
    strcpy(buf, selstr);
    return strlen(selstr);
  }

  return 0;
}

int s2e_web_get_stop_bits_selected(char buf[], int app_state, int connection_state, int stop_bits)
{
  chanend c_uart_config = (chanend) app_state;

  int id = update_cache(c_uart_config, connection_state);
  if (id == -1)
    return 0;

  if (cached_uart_data.stop_bits == stop_bits) {
    char selstr[] = "selected";
    strcpy(buf, selstr);
    return strlen(selstr);
  }

  return 0;
}



void s2e_webserver_init(chanend c_xtcp, chanend c_flash, chanend c_uart_config)
{
  web_server_init(c_xtcp, c_flash);
  web_server_set_app_state(c_uart_config);
  cached_uart_data.channel_id = -1;
}

void s2e_webserver_event_handler(chanend c_xtcp,
                      chanend c_flash,
                      chanend c_uart_config,
                      REFERENCE_PARAM(xtcp_connection_t, conn))
{
  web_server_handle_event(c_xtcp, c_flash, conn);
}

