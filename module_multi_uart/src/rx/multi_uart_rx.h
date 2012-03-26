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
// this is not required to be defined, but is used in the code
#else
#error "No RX UART Configuration file"
#endif /* __multi_uart_rx_conf_h_exists__ */

/* define channel commands */
#define UART_RX_STOP    0xFF
#define UART_RX_GO    0xFE

/**
 * Structure used to hold ports - used to enable extensibility in the future
 */
typedef struct STRUCT_MULTI_UART_RX_PORTS
{
#ifdef __XC__
    buffered in port:32 pUart;
#else
    unsigned pUart;
#endif
} s_multi_uart_rx_ports;

/**
 * Structure to hold configuration information and data for the UART channel RX side - 
 * this should only be interacted with via the API and not accessed directly.
 */
typedef struct STRUCT_MULTI_UART_RX_CHANNEL
{
    
    int uart_char_len; /**< length of the UART character */
    int uart_word_len; /**< number of bits in UART word e.g. Start bit + 8 bit data + parity + 2 stop bits is a 12 bit UART word */
    int clocks_per_bit; /**< define baud rate in relation to max baud rate */
    int invert_output; /**< define if output is inverted (set to 1) */
    int use_sample; /**< sample in bit stream to use */
    
    
    e_uart_config_stop_bits sb_mode; /**< Stop bit configuration */
    e_uart_config_parity parity_mode; /**< Parity mode configuration */
    e_uart_config_polarity polarity_mode; /**< Polarity mode */

} s_multi_uart_rx_channel;


/**
 * Configure the UART channel
 * @param[in] channel_id    Channel Identifier
 * @param[in] parity        Parity configuration
 * @param[in] stop_bits     Stop bit configuration
 * @param[in] polarity      Polarity configuration (currently unused)
 * @param[in] baud          Required baud rate
 * @param[in] char_len      Length of a character in bits (e.g. 8 bits)
 * @return              Return 0 on success
 */
int uart_rx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, e_uart_config_polarity polarity, int baud, int char_len );

/**
 * Validate received UART word according to channel configuration and provide a cleaned UART 
 * character
 * @param[in]           chan_id     UART channel ID from which the char came from
 * @param[in,out]   uart_word   UART char in the format DATA_BITS|PARITY|STOP BITS (parity optional
 *                              according to config), modified to clean UART charcater on successful *                              return
 * @return              Return 0 on valid data, -1 on validation fail 
 */
int uart_rx_validate_char( int chan_id, REFERENCE_PARAM(unsigned,uart_word) );

/**
 * Get the received value from an RX slot
 * @param   chan_id     channel id to grab
 * @return              value in slot
 */
unsigned uart_rx_grab_char( unsigned chan_id );

/**
 * Multi-UART Receive Server
 * @param   cUART       channel interface for RX UART
 * @param   tx_ports    port structure
 * @param   uart_clock  clock block for UART
 */
void run_multi_uart_rx( streaming chanend cUART, REFERENCE_PARAM(s_multi_uart_rx_ports, tx_ports), clock uart_clock );

/**
 * Pause the UART via channel for reconfiguration
 * @param   cUART   streaming channel end to RX server
 */
void uart_rx_reconf_pause( streaming chanend cUART );

/**
 * Release the UART into normal operation - must be called after uart_rx_reconf_pause
 * @param cUART channel end to RX UART
 */
void uart_rx_reconf_enable( streaming chanend cUART );
 
#endif /* __MULTI_UART_RX_H__ */
