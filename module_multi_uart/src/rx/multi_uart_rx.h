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
#error "No RX UART Configuration file"
#endif /* __multi_uart_rx_conf_h_exists__ */

/* define channel commands */
#define UART_RX_STOP    0xFF
#define UART_RX_GO    0xFE

typedef struct STRUCT_MULTI_UART_RX_PORTS
{
#ifdef __XC__
    buffered in port:32 pUart;
#else
    unsigned pUart;
#endif
} s_multi_uart_rx_ports;

typedef struct STRUCT_MULTI_UART_RX_CHANNEL
{
    /* configuration constants */
    int uart_char_len; // length of the UART char
    int uart_word_len; // number of bits in UART word e.g. Start bit + 8 bit data + parity + 2 stop bits is 12 bit UART word
    int clocks_per_bit; // define baud rate in relation to max baud rate
    int invert_output; // define if output is inverted (set to 1)
    int use_sample; // sample in stream to use
    
    /* mode definition */
    e_uart_config_stop_bits sb_mode;
    e_uart_config_parity parity_mode;
    e_uart_polarity polarity_mode;
    
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
int uart_rx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, e_uart_polarity polarity, int baud, int char_len );

/**
 * Validate RX'd character
 * @param   chan_id     uart channel id from which the char came from
 * @param   uart_word   uart char in the format DATA_BITS|PARITY|STOP BITS (parity optional according to config)
 * @return              Return 0 on valid data, -1 on stop bit fail - remaining character in uart_word 
 */
int uart_rx_validate_char( int chan_id, REFERENCE_PARAM(unsigned,uart_word) );

/**
 * Get the value from a RX slot
 * @param   chan_id     channel id to grab
 * @return              value in slot
 */
unsigned uart_rx_grab_char( unsigned chan_id );

/**
 * Multi UART Receive Thread
 * @param   cUART       channel interface for RX UART
 * @param   tx_ports    port structure
 * @param   uart_clock  clock block for UART
 */
void run_multi_uart_rx( streaming chanend cUART, REFERENCE_PARAM(s_multi_uart_rx_ports, tx_ports), clock uart_clock );

/**
 * Pause the UART via channel
 * @param   cUART   streaming channel end to RX server
 */
void uart_rx_reconf_pause( streaming chanend cUART );

/**
 * Release the UART into normal operation - must be called after uart_rx_reconf_pause
 * @param cUART channel end to RX UART
 */
void uart_rx_reconf_enable( streaming chanend cUART );
 
#endif /* __MULTI_UART_RX_H__ */
