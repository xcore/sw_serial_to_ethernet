/*
 * Multi-UART Receive Configuration file
 */

/**
 * Define the external clock rate
 */
#define UART_RX_CLOCK_RATE_HZ      100000000 //1843200

/**
 * Clock divider value that defines max baud rate. E.g. with external 1.8432MHz clock
 * Div 16 => 115200 max bps
 * Div 8  => 230400 max bps
 * Div 4  => 460800 max bps
 */
#define UART_RX_CLOCK_DIVIDER      500

/**
 * Define the buffer size in UART word entries - needs to be a power of 2 (i.e. 1,2,4,8,16,32)
 */
#define UART_RX_BUF_SIZE    16

/**
 * Define the number of channels that are to be supported, must fit in the port. Also, 
 * must be a power of 2 (i.e. 1,2,4,8,16) - not all channels have to be utilised
 */
#define UART_RX_CHAN_COUNT  1
