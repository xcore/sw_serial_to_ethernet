#include "multi_uart_tx.h"
#include "multi_uart_helper.h"

s_multi_uart_tx_channel uart_tx_channel[UART_TX_CHAN_COUNT];

unsigned crc8_helper(unsigned *checksum, unsigned data, unsigned poly);

/**
 * Calculate if the baud rate is valid for the defined divider 
 * @param baud  Requested baud rate                                                 
 * @return      Divider on success (i.e. >=1), 0 on error
 */
static int uart_tx_calc_baud( int baud )
{
    int max_baud = UART_TX_MAX_BAUD_RATE;
    
    /* check we are not requesting a value greater than the max */
    if (baud > max_baud)
        return 0;
    
    #ifdef UART_TX_USE_EXTERNAL_CLOCK
    if (UART_TX_CLOCK_RATE_HZ % baud != 0)
        return 0; 
    
    return (UART_TX_CLOCK_RATE_HZ/baud)/(UART_TX_CLOCK_RATE_HZ/UART_TX_MAX_BAUD_RATE);
    #else
    /* checks and calculations for internal clocking */
    /* check we divide exactly */
    if (max_baud % baud != 0)
        return 0; 
    
    return (max_baud / baud)*UART_TX_OVERSAMPLE; // return clock divider
    #endif
}

/**
 * Calculate parity according to the configuration
 * @param channel_id    Channel identifier
 * @param uart_char     The character being sent
 * @return              Parity value
 */
static unsigned uart_tx_calc_parity(int channel_id, unsigned int uart_char)
{
    unsigned p=0;
    
    switch (uart_tx_channel[channel_id].parity_mode)
    {
        case mark:
            return 1;
        case space:
            return 0;
        default:
            break;
    }
        
    if (uart_tx_channel[channel_id].uart_char_len != 8)
    {
        /* manually calculate parity */
        p = uart_char & 1;
        for (int i = 1; i < uart_tx_channel[channel_id].uart_char_len; i++)
        {
            p ^= ((uart_char >> i) & 1);
        }
        
    }
    else
    {
        int poly = 0x1;
        p = uart_char;
        crc8_helper(&p, uart_char, poly);
    }
    
    p &= 1;
    
    switch (uart_tx_channel[channel_id].parity_mode)
    {
        case even:
            return (p);
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
int uart_tx_initialise_channel( int channel_id, e_uart_config_parity parity, e_uart_config_stop_bits stop_bits, e_uart_config_polarity polarity, int baud, int char_len )
{
    /* check and calculate baud rate divider */
    if ((uart_tx_channel[channel_id].clocks_per_bit = uart_tx_calc_baud(baud)) == 0)
        return 1;
    
    /* set operation mode */
    uart_tx_channel[channel_id].sb_mode = stop_bits;
    uart_tx_channel[channel_id].parity_mode = parity;
    uart_tx_channel[channel_id].polarity_mode = polarity;
    
    /* set the uart character length */
    uart_tx_channel[channel_id].uart_char_len = char_len;
    
    /* calculate word length */
    uart_tx_channel[channel_id].uart_word_len = 1; // start bit
    switch (parity)
    {
        case odd:
        case even:
        case mark:
        case space:
            uart_tx_channel[channel_id].uart_word_len += 1;
            break;
        case none:
            break;
    }
    
    switch (stop_bits)
    {
        case sb_1:
            uart_tx_channel[channel_id].uart_word_len += 1;
            break;
        case sb_2:
            uart_tx_channel[channel_id].uart_word_len += 2;
            break;
    }
    
    uart_tx_channel[channel_id].uart_word_len += char_len;
    
    /* add interframe bits */
    uart_tx_channel[channel_id].uart_word_len += UART_TX_IFB;
    
    return 0;
}

/**
 * Assemble tx full word
 * @param channel_id    Channel identifier
 * @param uart_char     The character being sent
 * @return              Full UART word in the format (msb -> lsb) STOP|PARITY|DATA|START 
 */
unsigned int uart_tx_assemble_word( int channel_id, unsigned int uart_char )
{
    unsigned int full_word;
    unsigned int temp;
    int pos = 0;
    
    /* format data into the word (msb -> lsb) STOP|PARITY|DATA|START */
    
    /* start bit */
    switch (uart_tx_channel[channel_id].polarity_mode)
    {
        case start_0: full_word = 0; break;
        case start_1: full_word = 1; break;
        default: full_word = 0; break;
    }
    
    pos += 1;
    
    /* uart word - mask, reverse char and put into full word */
    temp = (((1 << uart_tx_channel[channel_id].uart_char_len) - 1) & uart_char);
    full_word |=  temp << pos;
    pos += uart_tx_channel[channel_id].uart_char_len;
    
    /* parity */
    if (uart_tx_channel[channel_id].parity_mode != none)
    {
        int parity = uart_tx_calc_parity(channel_id, uart_char);
        full_word |= ( parity << pos);
        pos += 1;
    }
    
    
    /* setup polarity for stop bits */
    switch (uart_tx_channel[channel_id].polarity_mode)
    {
        case start_0: temp = 0x3; break;
        case start_1: temp = 0x0; break;
        default: temp = 0x3; break;
    }
    
    /* stop bits */
    switch (uart_tx_channel[channel_id].sb_mode)
    {
        case sb_1:
            full_word |= (0x1&temp) << pos;
            pos += 1;
            break;
        case sb_2:
            full_word |= (0x3&temp) << pos;
            pos += 2;
            break;
    }
    
    full_word |= ((1 << UART_TX_IFB) - 1) << pos;
    
    /* mask off word to uart word length */
    full_word = (((1 << uart_tx_channel[channel_id].uart_word_len) - 1) & full_word);
    
    /* do calc XOR'd output */
    temp = (full_word << 1) | 0x1;
    full_word = temp ^ full_word;
    
    return full_word;
}

/**
 * Insert a UART Character into the appropriate UART buffer
 * @param channel_id    Channel identifier
 * @param uart_char     Character to be sent over UART
 * @return              0 if OK, -1 for full
 */
int uart_tx_put_char( int channel_id, unsigned int uart_char )
{
    if (((uart_tx_channel[channel_id].wr_ptr+1)&(UART_TX_BUF_SIZE-1)) != uart_tx_channel[channel_id].rd_ptr) // ensure this write would not overwrite the current read
    {
        unsigned uart_word = uart_tx_assemble_word( channel_id, uart_char );
        int wr_ptr = uart_tx_channel[channel_id].wr_ptr;
        uart_tx_channel[channel_id].buf[wr_ptr] = uart_word;
        wr_ptr++;
        if (wr_ptr >= UART_TX_BUF_SIZE)
            wr_ptr = 0;
        uart_tx_channel[channel_id].wr_ptr = wr_ptr;
        return 0;
    }
    else return -1;
}

/**
 * Pause the Multi-UART TX thread for reconfiguration
 * @param cUART     chanend to UART TX thread
 * @param t         timer for running buffer clearance pause
 */
void uart_tx_reconf_pause( chanend cUART, timer t )
{
    unsigned pause_time;
    unsigned min_baud_chan;
    unsigned temp = 0;
    
    /* find slowest channel - which is max(clocks_per_bit)*/
    for (int i = 0; i < UART_TX_CHAN_COUNT; i++)
    {
        if (temp < uart_tx_channel[i].clocks_per_bit)
        {
            temp = uart_tx_channel[i].clocks_per_bit;
            min_baud_chan = i;
        }
    }
    
    /* calculate baud rate from clocks per bit*/
    #ifdef UART_TX_USE_EXTERNAL_CLOCK
    pause_time = (UART_TX_CLOCK_RATE_HZ)/(uart_tx_channel[min_baud_chan].clocks_per_bit * (UART_TX_CLOCK_RATE_HZ/UART_TX_MAX_BAUD_RATE));
    #else
    pause_time = ((UART_TX_MAX_BAUD_RATE)*UART_TX_OVERSAMPLE)*uart_tx_channel[min_baud_chan].clocks_per_bit;
    #endif
    
    /* calculate uart word rate, add margin for any IWD */
    pause_time = pause_time / (uart_tx_channel[min_baud_chan].uart_word_len+2);
    
    /* get number of clock ticks per word */
    pause_time = 100000000 / pause_time;
    
    /* get total time to complete a buffer */
    pause_time = pause_time * UART_TX_BUF_SIZE;
    
    /* pause for buffer empty */
    wait_for(t, pause_time );
    
    /* request pause */
    send_streaming_int(cUART, 0); 
    temp = 0;
    do 
    {
        temp = get_streaming_uint(cUART); // wait for UART to be ready for reconf
    } while (temp != MULTI_UART_GO);
    
}

/**
 * Release the UART into normal operation - must be called after uart_tx_reconf_pause
 * @param cUART channel end to TX UART
 */
void uart_tx_reconf_enable( chanend cUART )
{
    send_streaming_int(cUART, 1); // done - let the UART commence
}
