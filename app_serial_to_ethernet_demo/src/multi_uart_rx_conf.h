/*
 * Multi-UART Receive Configuration file
 */

/**
 * Define the number of channels that are to be supported, must fit in the port. Also, 
 * must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised
 */
#define UART_RX_CHAN_COUNT  8
 
/**
 * Define the system clock rate
 */
#define UART_RX_CLOCK_RATE_HZ      100000000

/**
 * Define the max baud rate - validated to 115200 baud
 */
#define UART_RX_MAX_BAUD    115200

/**
 * Clock divider value that defines max baud rate. E.g. with external 1.8432MHz clock
 * Div 16 => 115200 max bps
 * Div 8  => 230400 max bps
 * Div 4  => 460800 max bps
 */
#define UART_RX_CLOCK_DIVIDER      (UART_RX_CLOCK_RATE_HZ/UART_RX_MAX_BAUD)

/**
 * Define oversample for max baud. This should be left at 4
 */
#define UART_RX_OVERSAMPLE 4

