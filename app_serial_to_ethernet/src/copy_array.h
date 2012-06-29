#include <xccompat.h>
#include "uart_config.h"

int copy_config_from_array(char data[],
                           int i,
                           REFERENCE_PARAM(uart_config_data_t, config),
                           REFERENCE_PARAM(int, telnet_port));

int copy_config_to_array(char data[],
                         int i,
                         REFERENCE_PARAM(uart_config_data_t, config),
                         int telnet_port);
