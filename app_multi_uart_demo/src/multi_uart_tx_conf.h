/*
 * Multi-UART Transmit Configuration file
 */

/**
 * Define the external clock rate
 */
#define UART_TX_CLOCK_RATE_HZ      100000000 //1843200


/**
 * Define the max baud rate
 */
#define UART_TX_MAX_BAUD_RATE   100000


/**
 * Clock divider value that defines max baud rate. For external 1.8432MHz clock
 * Div 16 => 115200 max bps
 * Div 8  => 230400 max bps
 * Div 4  => 460800 max bps
 */
#define UART_TX_CLOCK_DIVIDER      (UART_TX_CLOCK_RATE_HZ/UART_TX_MAX_BAUD_RATE)

/**
 * Define the oversampling of the clock - this is where the UART_TX_CLOCK_DIVIDER is > 255 
 * (otherwise set to 1)
 */
#define UART_TX_OVERSAMPLE          2

/**
 * Define the buffer size in UART word entries - needs to be a power of 2 (i.e. 1,2,4,8,16,32)
 */
#define UART_TX_BUF_SIZE    16

/**
 * Define the number of channels that are to be supported, must fit in the port. Also, 
 * must be a power of 2 (i.e. 1,2,4,8,16) - not all channels have to be utilised
 */
#define UART_TX_CHAN_COUNT  8
