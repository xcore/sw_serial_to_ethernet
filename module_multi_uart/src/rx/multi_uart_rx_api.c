#include "multi_uart_rx.h"

s_multi_uart_rx_channel uart_rx_channel[UART_RX_CHAN_COUNT];

unsigned crc8_helper(unsigned *checksum, unsigned data, unsigned poly);

/**
 * Calculate if the baud rate is valid for the defined divider 
 * @param baud  Requested baud rate                                                 
 * @return      Divider on success (i.e. >=1), 0 on error
 */
static int uart_rx_calc_baud( int baud )
{
    int max_baud = UART_RX_CLOCK_RATE_HZ / (UART_RX_CLOCK_DIVIDER);
    
    /* check we are not requesting a value greater than the max */
    if (baud > max_baud)
        return 0;
    
    /* check we divide exactly */
    if (max_baud % baud != 0)
        return 0;
    
    return ((max_baud / baud)*4); // return clock divider - we oversample by 4 at max baud
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
        crc8_helper(&p, uart_char, poly);
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
    //uart_rx_channel[channel_id].uart_word_len += 1; // start bit ignored as this is used as a state machine condition for counting in bits - start bit is handled in its own state.
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
 * Get a UART Character from the appropriate UART buffer
 * @param channel_id    Channel identifier
 * @param uart_char     Returned UART char
 * @return              Buffer fill levels, -1 if empty
 */
int uart_rx_get_char( int channel_id, REFERENCE_PARAM(unsigned,uart_char) )
{
    if (uart_rx_channel[channel_id].nelements > 0)
    {
        int rd_ptr = uart_rx_channel[channel_id].rd_ptr;
        *uart_char = uart_rx_channel[channel_id].buf[rd_ptr];
        rd_ptr++;
        rd_ptr &= (UART_RX_BUF_SIZE-1);
        uart_rx_channel[channel_id].rd_ptr = rd_ptr;
        uart_rx_channel[channel_id].nelements--;
        return uart_rx_channel[channel_id].nelements;
    }
    else return -1;
}

