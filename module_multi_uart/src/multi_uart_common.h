#ifndef __MULTI_UART_COMMON_H__
#define __MULTI_UART_COMMON_H__

/* define channel commands */
#define MULTI_UART_STOP     0xFF
#define MULTI_UART_GO       0xFE

typedef enum ENUM_UART_RX_CONFIG_PARITY
{
    odd = 0x1,
    even = 0x2,
    mark = 0x3,
    space = 0x4,
    none = 0x0
} e_uart_config_parity;

typedef enum ENUM_UART_RX_CONFIG_STOP_BITS
{
    sb_1,
    sb_2,
} e_uart_config_stop_bits;

typedef enum ENUM_UART_RX_CONFIG_POLARITY
{
    start_1 = 1,
    start_0 = 0,
} e_uart_polarity; 

#endif /* __MULTI_UART_COMMON_H__ */
