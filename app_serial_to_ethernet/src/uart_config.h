#ifndef __uart_config_h__
#define __uart_config_h__
#include "xccompat.h"

#include "multi_uart_common.h"

typedef struct uart_config_data_t
{
    int channel_id;
    e_uart_config_parity parity;
    e_uart_config_stop_bits stop_bits;
    e_uart_config_polarity polarity;
    int baud;
    int char_len;
} uart_config_data_t;

#ifndef __XC__
/* Get the configuration structure for a uart */
uart_config_data_t *uart_get_config(int i);
#endif

void uart_config_init(chanend c_uart_config,
                NULLABLE_RESOURCE(chanend, c_flash_data),
                NULLABLE_RESOURCE(chanend, c_xtcp),
                REFERENCE_PARAM(int, telnet_port_address));

#endif
