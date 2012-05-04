#ifndef __MULTI_UART_COMMON_H__
#define __MULTI_UART_COMMON_H__

/* define channel commands */
#define MULTI_UART_GO 0xFE

/**
 * Define the parity configuration
 */
typedef enum ENUM_UART_CONFIG_PARITY
{
    odd = 0x1, /**< Odd parity **/
    even = 0x2, /**< Even parity **/
    mark = 0x3, /**< Mark (always 1) parity bit **/
    space = 0x4, /**< Space (always 0) parity bit **/
    none = 0x0 /**< No parity bit */
} e_uart_config_parity;

/**
 * Configure the number of stop bits
 */
typedef enum ENUM_UART_CONFIG_STOP_BITS
{
    sb_1, /**< Single stop bit */
    sb_2, /**< Two stop bits */
} e_uart_config_stop_bits;

/**
 * Start bit polarity configuration (currently unused)
 */
typedef enum ENUM_UART_CONFIG_POLARITY
{
    start_1 = 1, /**< Start bit is a 1, implies stop bit/idle is a 0 */
    start_0 = 0, /**< Start bit is a 0, implies stop bit/idle is a 1 */
} e_uart_config_polarity; 

#endif /* __MULTI_UART_COMMON_H__ */
