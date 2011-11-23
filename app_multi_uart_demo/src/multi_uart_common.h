#ifndef __MULTI_UART_COMMON_H__
#define __MULTI_UART_COMMON_H__

/* define channel commands */
#define MULTI_UART_STOP     0xFF
#define MULTI_UART_GO       0xFE

typedef enum ENUM_UART_RX_CONFIG_PARITY
{
    odd,
    even,
    mark,
    space,
    none
} e_uart_config_parity;

typedef enum ENUM_UART_RX_CONFIG_STOP_BITS
{
    sb_1,
    sb_2,
} e_uart_config_stop_bits; 

#endif /* __MULTI_UART_COMMON_H__ */
