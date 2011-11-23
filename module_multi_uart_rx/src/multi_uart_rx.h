#ifndef __MULTI_UART_RX_H__
#define __MULTI_UART_RX_H__

#include <xs1.h>
#include <xccompat.h>
#include <xclib.h>
#include "multi_uart_common.h"

#ifdef __STDC__
#define streaming
#endif

#ifdef __multi_uart_rx_conf_h_exists__
#include "multi_uart_rx_conf.h"
#else

/**
 * Define the external clock rate
 */
#define UART_RX_CLOCK_RATE_HZ      1843200

/**
 * Clock divider value that defines max baud rate. For external 1.8432MHz clock
 * Div 16 => 115200 max bps
 * Div 8  => 230400 max bps
 * Div 4  => 460800 max bps
 */
#define UART_RX_CLOCK_DIVIDER      8

/**
 * Define the buffer size in bytes - full UART words are stored in this buffer, so if 2 bytes per word are required (e.g. 12 bit UART word) then this must be accounted for
 */
#define UART_RX_BUF_SIZE    16

/**
 * Define the number of channels that are to be supported
 */
#define UART_RX_CHAN_COUNT  8

#endif /* __multi_uart_rx_conf_h_exists__ */

/* define channel commands */
#define UART_RX_STOP    0xFF
#define UART_RX_GO    0xFE

typedef struct STRUCT_MULTI_UART_RX_PORTS
{
#ifdef __XC__
    buffered in port:8 pUart;
    in port pUartClk;
    clock cbUart;
#else
    unsigned pUart;
    unsigned pUartClk;
    clock cbUart;
#endif
} s_multi_uart_rx_ports;

typedef struct STRUCT_MUTI_UART_RX_CHANNEL
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
    unsigned buf[UART_RX_BUF_SIZE];
    
} s_multi_uart_rx_channel;


/**
 * Configure the UART channel
 * @param channel_id    Channel Identifier
 * @param op_mode       Mode of operation
 * @param baud          Required baud rate
 * @param char_len      Length of a character in bits (e.g. 8 bits)
 * @return              Return 0 on success
 */
int uart_rx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, int baud, int char_len );

/**
 * Insert a UART Character into the appropriate UART buffer
 * @param channel_id    Channel identifier
 * @param uart_char     Character to be sent over UART
 * @return              Buffer fill level
 */
int uart_rx_get_char( int channel_id, REFERENCE_PARAM(unsigned,uart_char) );

/**
 * Multi UART Receive Thread
 */
void run_multi_uart_rx( streaming chanend cUART, REFERENCE_PARAM(s_multi_uart_rx_ports, tx_ports) );

 
#endif /* __MULTI_UART_RX_H__ */
