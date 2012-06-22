#include "uart_config.h"
#include "uart_handler.h"
#include "telnet_to_uart.h"
#include "s2e_conf.h"
#include "s2e_def.h"
#include "s2e_flash.h"

static uart_config_data_t uart_config[NUM_UART_CHANNELS];

uart_config_data_t *uart_get_config(int i)
{
  return &uart_config[i];
}

void uart_config_init(chanend c_uart_config, chanend c_flash_data, chanend c_xtcp)
{
    uart_config_data_t data1;
    int telnet_port1;
    int flash_result;

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
        for (int i = 0; i < NUM_UART_CHANNELS; i++)
        {
            uart_config[i].channel_id = i;
            uart_config[i].parity = even;
            uart_config[i].stop_bits = sb_1;
            uart_config[i].baud = 115200;
            uart_config[i].polarity = start_0;
            uart_config[i].char_len = 8;
            uart_set_config(c_uart_config, &uart_config[i]);
            telnet_to_uart_set_port(c_xtcp, uart_config[i].channel_id, (TELNET_UART_BASE_PORT + i));
        }
    }
}

