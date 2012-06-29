#include <string.h>
#include "copy_array.h"

/* Save */
int copy_config_to_array(char data[], int i, uart_config_data_t *config, int telnet_port)
{
    memcpy(&data[i], (char *) &telnet_port, sizeof(int));
    i+=sizeof(int);
    memcpy(&data[i], (char *) config, sizeof(uart_config_data_t));
    i+=sizeof(uart_config_data_t);
    return i;
}

/* Restore */
int copy_config_from_array(char data[], int i, uart_config_data_t *config, int *telnet_port)
{
    memcpy((char *) telnet_port, &data[i], sizeof(int));
    i+=sizeof(int);
    memcpy((char *) config, &data[i], sizeof(uart_config_data_t));
    i+=sizeof(uart_config_data_t);
    return i;
}
