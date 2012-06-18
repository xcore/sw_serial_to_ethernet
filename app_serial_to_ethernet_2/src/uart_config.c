#include "uart_config.h"
#include "uart_handler.h"
#include "s2e_conf.h"
#include "s2e_def.h"

static uart_config_data_t uart_config[NUM_UART_CHANNELS];

uart_config_data_t *uart_get_config(int i)
{
  return &uart_config[i];
}

void uart_config_init(chanend c_uart_config)
{
  for (int i=0;i<NUM_UART_CHANNELS;i++) {
    uart_config[i].channel_id = i;
    uart_config[i].parity = even;
    uart_config[i].stop_bits = sb_1;
    uart_config[i].baud = 115200;
    uart_config[i].polarity = start_0;
    uart_config[i].char_len = 8;
    uart_set_config(c_uart_config, &uart_config[i]);
  }
}

