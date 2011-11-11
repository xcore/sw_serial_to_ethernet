#ifndef __MULTI_UART_TX_H__
#define __MULTI_UART_TX_H__

#include <xs1.h>
#include <xccompat.h>
#include <xclib.h>

#ifdef __multi_uart_tx_conf_h_exists__
#include "multi_uart_tx_conf.h"
#else

/**
 * Define the external clock rate
 */
#define UART_CLOCK_RATE_HZ      1843200

/**
 * Clock divider value that defines max baud rate. For external 1.8432MHz clock
 * Div 16 => 115200 max bps
 * Div 8  => 230400 max bps
 * Div 4  => 460800 max bps
 */
#define UART_CLOCK_DIVIDER      8

/**
 * Define the buffer size in bytes - full UART words are stored in this buffer, so if 2 bytes per word are required (e.g. 12 bit UART word) then this must be accounted for
 */
#define UART_TX_BUF_SIZE    16

/**
 * Define the number of channels that are to be supported
 */
#define UART_TX_CHAN_COUNT  8

#endif /* __multi_uart_tx_conf_h_exists__ */

/* define channel commands */
#define UART_TX_STOP    0xFF
#define UART_TX_GO    0xFE


typedef enum ENUM_UART_TX_CONFIG_PARITY
{
    odd,
    even,
    mark,
    space,
    none
} e_uart_tx_config_parity;

typedef enum ENUM_UART_TX_CONFIG_STOP_BITS
{
    sb_1,
    sb_2,
} e_uart_tx_config_stop_bits;

#ifdef __XC__
typedef struct STRUCT_MULTI_UART_TX_PORTS
{
    buffered out port:8 pUart;
    in port pUartClk;
    clock cbUart;
} s_multi_uart_tx_ports;
#else
typedef struct STRUCT_MULTI_UART_TX_PORTS
{
    unsigned pUart;
    unsigned pUartClk;
    clock cbUart;
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
    e_uart_tx_config_stop_bits sb_mode;
    e_uart_tx_config_parity parity_mode;
    
    /* internal channel variables */
    int current_word; // data currently being output
    int current_word_pos; // current shift position in the word
    int tick_count; // counter for number of divided clock ticks per bit    
    
    /* buffering variables */
    int wr_ptr;
    int rd_ptr;
    int nelements;
    int nMax;
    int buf_empty;
    int inc; // increment for a full word
    char buf[UART_TX_BUF_SIZE]; // buffer holding complete words
    
} s_multi_uart_tx_channel;


/**
 * Configure the UART channel
 * @param channel_id    Channel Identifier
 * @param op_mode       Mode of operation
 * @param baud          Required baud rate
 * @param char_len      Length of a character in bits (e.g. 8 bits)
 * @return              Return 0 on success
 */
int uart_tx_initialise_channel( int channel_id, e_uart_tx_config_parity parity, e_uart_tx_config_stop_bits stop_bits, int baud, int char_len );

/**
 * Assemble full word for transmission
 * @param channel_id    Channel identifier
 * @param uart_char     The character being sent
 * @return              Full UART word in the format (msb -> lsb) STOP|PARITY|DATA|START 
 */
unsigned int uart_tx_assemble_word( int channel_id, unsigned int uart_char );

/**
 * Multi UART Transmit Thread
 */
void run_multi_uart_tx( chanend cUART, REFERENCE_PARAM(s_multi_uart_tx_ports, tx_ports) );

 
#endif /* __MULTI_UART_TX_H__ */
