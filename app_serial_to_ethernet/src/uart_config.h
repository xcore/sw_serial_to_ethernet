#ifndef __uart_config_h__
#define __uart_config_h__
#include "xccompat.h"

#include "multi_uart_common.h"

/**
 * Structure to hold UART configuration details
 */
typedef struct uart_config_data_t
{
    int channel_id; /**< UART Id */
    e_uart_config_parity parity; /**< One of valid parity: Odd, Even, Mark, Space, None */
    e_uart_config_stop_bits stop_bits; /**< Stop bits configuration: Single or Two */
    e_uart_config_polarity polarity; /**< Polarity setting: Start bit as 1 or 0 */
    int baud; /**< Baud rate of UART channel */
    int char_len; /**< Number of bits each UART character contain */
} uart_config_data_t;

#ifndef __XC__
/* Get the configuration structure for a uart */
uart_config_data_t *uart_get_config(int i);
#endif

/**
 * This function retrieves configuration of each UARTs from flash, and applies
 * it to the base configuration structure of type uart_config_data_t. Telnet
 * port applicable for corresponding UART is also fetched from flash and applied
 * to repective UART configuration structure. If there is no valid flash
 * configuration, default in-program configuration with following values
 * EvenParity-1StopBit-115200Baud-Start0Polarity-8UARTCharLen is used
 * @param     c_uart_config Channel-end to communicate UART configuration
 *             details between TCP handler and UART handler thread
 * @param     c_flash_data Channel-end to communicate UART configuration data
 *             stored in flash to TCP handler thread
 * @param     c_xtcp        Channel-end between XTCP and TCP handler thread
 * @param     telnet_port_address Reference to structure holding Telnet port addresses
 *             mapped for UARTs
 * @return              None
 */
void uart_config_init(chanend c_uart_config,
                NULLABLE_RESOURCE(chanend, c_flash_data),
                NULLABLE_RESOURCE(chanend, c_xtcp),
                REFERENCE_PARAM(int, telnet_port_address));

#endif
