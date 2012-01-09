#ifndef __MULTI_UART_TX_H__
#define __MULTI_UART_TX_H__

#include <xs1.h>
#include <xccompat.h>
#include <xclib.h>
#include "multi_uart_common.h"

#ifdef __STDC__
#define streaming
#endif

#ifdef __multi_uart_tx_conf_h_exists__
#include "multi_uart_tx_conf.h"
#else

/**
 * Define to use external clock reference
 */
#define UART_TX_USE_EXTERNAL_CLOCK

/**
 * Define the external clock rate
 */
#define UART_CLOCK_RATE_HZ      1843200

/**
 * Define the max baud rate - validated to 230kbaud
 */
#define UART_TX_MAX_BAUD_RATE   100000

/**
 * Clock divider value that defines max baud rate - this is only used when using the internal clock
 */
#define UART_TX_CLOCK_DIVIDER      (UART_TX_CLOCK_RATE_HZ/UART_TX_MAX_BAUD_RATE)

/**
 * Define the oversampling of the clock - this is where the UART_TX_CLOCK_DIVIDER is > 255 
 * (otherwise set to 1) - only used when using an internal clock reference
 */
#define UART_TX_OVERSAMPLE          2

/**
 * Define the buffer size in bytes - full UART words are stored in this buffer, so if 2 bytes per word are required (e.g. 12 bit UART word) then this must be accounted for
 */
#define UART_TX_BUF_SIZE    16

/**
 * Define the number of channels that are to be supported
 */
#define UART_TX_CHAN_COUNT  8

#endif /* __multi_uart_tx_conf_h_exists__ */

#ifdef __XC__
typedef struct STRUCT_MULTI_UART_TX_PORTS
{
    buffered out port:8 pUart;
} s_multi_uart_tx_ports;
#else
typedef struct STRUCT_MULTI_UART_TX_PORTS
{
    unsigned pUart;
} s_multi_uart_tx_ports;
#endif

typedef struct STRUCT_MUTI_UART_TX_CHANNEL
{
    /* configuration constants */
    int uart_char_len; // length of the UART char
    int uart_word_len; // number of bits in UART word e.g. Start bit + 8 bit data + parity + 2 stop bits is 12 bit UART word
    int clocks_per_bit; // define baud rate in relation to max baud rate
    int invert_output; // define if output is inverted (set to 1)
    
    /* mode definition */
    e_uart_config_stop_bits sb_mode;
    e_uart_config_parity parity_mode;
    
    int wr_ptr;
    int rd_ptr;
    unsigned nelements;
    unsigned buf[UART_TX_BUF_SIZE];
    
} s_multi_uart_tx_channel;


/**
 * Configure the UART channel
 * @param channel_id    Channel Identifier
 * @param op_mode       Mode of operation
 * @param baud          Required baud rate
 * @param char_len      Length of a character in bits (e.g. 8 bits)
 * @return              Return 0 on success
 */
int uart_tx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, int baud, int char_len );

/**
 * Assemble full word for transmission
 * @param channel_id    Channel identifier
 * @param uart_char     The character being sent
 * @return              Full UART word in the format (msb -> lsb) STOP|PARITY|DATA|START 
 */
unsigned int uart_tx_assemble_word( int channel_id, unsigned int uart_char );

/**
 * Insert a UART Character into the appropriate UART buffer
 * @param channel_id    Channel identifier
 * @param uart_char     Character to be sent over UART
 * @param uart_clock    Clock block to run the port from
 * @return              Buffer fill level, -1 for full
 */
int uart_tx_put_char( int channel_id, unsigned int uart_char );

/**
 * Multi UART Transmit Thread
 */
void run_multi_uart_tx( streaming chanend cUART, REFERENCE_PARAM(s_multi_uart_tx_ports, tx_ports), clock uart_clock);

 
#endif /* __MULTI_UART_TX_H__ */
