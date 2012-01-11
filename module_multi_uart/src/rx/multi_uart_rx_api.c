#include "multi_uart_rx.h"
#include <print.h>

s_multi_uart_rx_channel uart_rx_channel[UART_RX_CHAN_COUNT];

unsigned crc8_helper(unsigned *checksum, unsigned data, unsigned poly);

/**
 * Calculate if the baud rate is valid for the defined divider 
 * @param baud  Requested baud rate                                                 
 * @return      Divider on success (i.e. >=1), 0 on error
 */
static int uart_rx_calc_baud( int baud )
{
    int max_baud = UART_RX_MAX_BAUD; //UART_RX_CLOCK_RATE_HZ / (UART_RX_CLOCK_DIVIDER);
    
    /* check we are not requesting a value greater than the max */
    if (baud > max_baud)
    	return 0;

    
    /* check we divide exactly */
    if (max_baud % baud != 0)
        return 0;
    
    // return clock divider - this is the number of port ticks per bit
    return ((max_baud / baud) * UART_RX_OVERSAMPLE); 
}

/**
 * Calculate parity according to the configuration
 * @param channel_id    Channel identifier
 * @param uart_char     The character being sent
 * @return              Parity value
 */
static unsigned uart_rx_calc_parity(int channel_id, unsigned int uart_char)
{
    unsigned p;
    
    switch (uart_rx_channel[channel_id].parity_mode)
    {
        case mark:
            return 1;
        case space:
            return 0;
        default:
            break;
    }
        
    if (uart_rx_channel[channel_id].uart_char_len != 8)
    {
        /* manually calculate parity */
        p = uart_char & 1;
        for (int i = 1; i < uart_rx_channel[channel_id].uart_char_len; i++)
        {
            p ^= ((uart_char >> i) & 1);
        }
        
    }
    else
    {
        int poly = 0x1;
        p = uart_char;
        crc8_helper(&p, uart_char, poly);
        p &= 1;
    }
    
    switch (uart_rx_channel[channel_id].parity_mode)
    {
        case even:
            return p;
        case odd :
            return (!p);
        default:
            return (-1); // should never reach here
            break;
    }
}

/**
 * Configure the UART channel
 * @param channel_id    Channel Identifier
 * @param op_mode       Mode of operation
 * @param baud          Required baud rate
 * @param char_len      Length of a character in bits (e.g. 8 bits)
 * @return              Return 0 on success
 */
int uart_rx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, e_uart_polarity polarity, int baud, int char_len )
{
    /* check and calculate baud rate divider */
    if ((uart_rx_channel[channel_id].clocks_per_bit = uart_rx_calc_baud(baud)) == 0)
        return 1;
    
    /* set which sample we will use */
    uart_rx_channel[channel_id].use_sample = uart_rx_channel[channel_id].clocks_per_bit >> 1;
    
    /* set operation mode */
    uart_rx_channel[channel_id].sb_mode = stop_bits;
    uart_rx_channel[channel_id].parity_mode = parity;
    uart_rx_channel[channel_id].polarity_mode = polarity;
    
    /* set the uart character length */
    uart_rx_channel[channel_id].uart_char_len = char_len;
    
    /* calculate word length for data_bit state */
    uart_rx_channel[channel_id].uart_word_len = 0; // start bit ignored as this is used as a state machine condition for counting in bits - start bit is handled in its own state.
    switch (parity)
    {
        case odd:
        case even:
        case mark:
        case space:
            uart_rx_channel[channel_id].uart_word_len += 1;
            break;
        case none:
            break;
    }
    
    switch (stop_bits)
    {
        case sb_1:
            uart_rx_channel[channel_id].uart_word_len += 1;
            break;
        case sb_2:
            uart_rx_channel[channel_id].uart_word_len += 2;
            break;
    }
    
    uart_rx_channel[channel_id].uart_word_len += char_len;
    
    return 0;
}

/**
 * Validate RX'd character
 * @param   chan_id     uart channel id from which the char came from
 * @param   uart_word   uart char in the format DATA_BITS|PARITY|STOP BITS (parity optional according to config)
 * @return              Return 0 on valid data, -1 on stop bit fail - remaining character in uart_word 
 */
int uart_rx_validate_char( int chan_id, unsigned *uart_word )
{
    int error = 0;
        
    switch (uart_rx_channel[chan_id].sb_mode)
    {
        case sb_1:
            if ((*uart_word & 1) != 1) // TODO respect polarity
                error = 1;
            *uart_word >>= 1;
            break;
        case sb_2:
            if ((*uart_word & 0x3) != 0x3) // TODO respect polarity
                error = 1;
            *uart_word >>= 2;
            break;
    }
    
    if (error) return -1;
    
    switch (uart_rx_channel[chan_id].parity_mode)
    {
        case odd:
        case even:
        case mark:
        case space:
            if ((*uart_word&1) != uart_rx_calc_parity(chan_id, *uart_word>>1))
            {
                printhexln(uart_rx_calc_parity(chan_id, *uart_word>>1));
                error = 1;
            }
            *uart_word >>= 1;
            break;
        case none:
            break;
    }
    
    if (error) return -1;
       
    return 0;
}


