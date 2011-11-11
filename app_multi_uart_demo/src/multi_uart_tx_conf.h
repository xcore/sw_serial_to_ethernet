/*
 * Multi-UART Transmit Configuration file
 */

/**
 * Define the external clock rate
 */
#define UART_CLOCK_RATE_HZ      100000000 //1843200

/**
 * Clock divider value that defines max baud rate. For external 1.8432MHz clock
 * Div 16 => 115200 max bps
 * Div 8  => 230400 max bps
 * Div 4  => 460800 max bps
 */
#define UART_CLOCK_DIVIDER      1

/**
 * Define the buffer size in bytes - full UART words are stored in this buffer, so if 2 bytes per word are required (e.g. 12 bit UART word) then this must be accounted for
 */
#define UART_TX_BUF_SIZE    16

/**
 * Define the number of channels that are to be supported
 */
#define UART_TX_CHAN_COUNT  8
