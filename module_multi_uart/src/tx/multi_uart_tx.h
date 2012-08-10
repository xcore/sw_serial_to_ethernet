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
#error "No UART TX configuration header file"
#endif /* __multi_uart_tx_conf_h_exists__ */

/**
 * Structure used to hold ports - used to enable extensibility in the future
 */
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

/**
 * Structure to hold configuration information and data for the UART channel TX side - 
 * this should only be interacted with via the API and not accessed directly.
 */
typedef struct STRUCT_MULTI_UART_TX_CHANNEL
{
    /*@{*/
    /** Configuration constants */
    int uart_char_len; /**< length of the UART char */
    int uart_word_len; /**< number of bits in UART word e.g. Start bit + 8 bit data + parity + 2 stop bits is 12 bit UART word */
    int clocks_per_bit; /**< define baud rate in relation to max baud rate */
    int invert_output; /**< define if output is inverted (set to 1) */
    /*@}*/
    
    /*@{*/
    /** Mode definition */
    e_uart_config_stop_bits sb_mode;
    e_uart_config_parity parity_mode;
    e_uart_config_polarity polarity_mode;
    /*@}*/
    
    /*@{*/
    /** Buffering variables */
    int wr_ptr; /**< Write pointer */
    int rd_ptr; /**< Read pointer */
    unsigned nelements; /**< Number of valid entries in the buffer */
    unsigned buf[UART_TX_BUF_SIZE]; /**< Buffer array */
    /*@}*/
    
} s_multi_uart_tx_channel;


/**
 * Configure the UART channel
 * @param channel_id    Channel Identifier
 * @param parity        Parity configuration
 * @param stop_bits     Stop bit configuration
 * @param polarity      Start/Stop bit polarity setting
 * @param baud          Required baud rate
 * @param char_len      Length of a character in bits (e.g. 8 bits)
 * @return              Return 0 on success
 */
int uart_tx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, e_uart_config_polarity polarity, int baud, int char_len );

/**
 * Assemble full word for transmission
 * @param channel_id    Channel identifier
 * @param uart_char     The character being sent
 * @return              Full UART word in the format (msb -> lsb) STOP|PARITY|DATA|START 
 */
unsigned int uart_tx_assemble_word( int channel_id, unsigned int uart_char );

/**
 * Assemble UART word from UART Character and insert into the appropriate UART buffer
 * @param channel_id    Channel identifier
 * @param uart_char     Character to be sent over UART
 * @return              0 for OK, -1 for buffer full
 */
int uart_tx_put_char( int channel_id, unsigned int uart_char );

/**
 * Multi UART Transmit Thread
 */
void run_multi_uart_tx( streaming chanend cUART, REFERENCE_PARAM(s_multi_uart_tx_ports, tx_ports), clock uart_clock);

/**
 * Pause the Multi-UART TX thread for reconfiguration
 * @param cUART     chanend to UART TX thread
 * @param t         timer for running buffer clearance pause
 */
void uart_tx_reconf_pause( streaming chanend cUART, timer t );

/**
 * Release the UART into normal operation - must be called after uart_tx_reconf_pause
 * @param cUART channel end to TX UART
 */
void uart_tx_reconf_enable( streaming chanend cUART );
 
#endif /* __MULTI_UART_TX_H__ */
