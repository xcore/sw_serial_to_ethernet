#include "multi_uart_rx.h"
#include <print.h>

#define PORT_TS_INC 1

out port pState = XS1_PORT_8C;

extern s_multi_uart_rx_channel uart_rx_channel[UART_RX_CHAN_COUNT];

#define increment(a, inc)  { a = (a+inc); a *= !(a == UART_RX_BUF_SIZE); }

static unsigned crc8_helper( unsigned &checksum, unsigned data, unsigned poly )
{
    return crc8shr(checksum, data, poly);
}

void multi_uart_rx_port_init( s_multi_uart_rx_ports &rx_ports )
{
    if (UART_RX_CLOCK_DIVIDER > 1)
    {
        // TODO configuration for external clock
        configure_clock_ref( rx_ports.cbUart, UART_RX_CLOCK_DIVIDER/8 );	
    }
    
    configure_out_port(	rx_ports.pUart, rx_ports.cbUart, 1); // TODO honour stop bit polarity
    
    start_clock( rx_ports.cbUart );
}

#pragma unsafe arrays
void multi_uart_rx_buffer_put( int chan_id, unsigned int uart_word )
{
    
}


typedef enum ENUM_UART_RX_CHAN_STATE
{
    idle,
    start_bit,
    data_bits,
    parity,
    stop_bit    
} e_uart_rx_chan_state;

#pragma unsafe arrays
void run_multi_uart_rx( streaming chanend cUART, s_multi_uart_rx_ports &rx_ports )
{

    unsigned port_val;
    e_uart_rx_chan_state state[UART_RX_CHAN_COUNT];
    unsigned mask, word, fourBits, bit;
    int tick_adjustment;
    
    int tickcount[UART_RX_CHAN_COUNT];
    int bit_count[UART_RX_CHAN_COUNT];
    int last_bit_val[UART_RX_CHAN_COUNT];
    int uart_word[UART_RX_CHAN_COUNT];
    
    /*
     * Four bit look up table that takes the CRC32 with poly 0xf of the masked off 32 bit word 
     * from an 8 bit port and translates it into the 4 desired bits - huzzah!
     */
    unsigned fourBitLookup[16];
    fourBitLookup[15] = 0;
    fourBitLookup[7] = 1;
    fourBitLookup[13] = 2;
    fourBitLookup[5] = 3;
    fourBitLookup[0] = 4;
    fourBitLookup[8] = 5;
    fourBitLookup[2] = 6;
    fourBitLookup[10] = 7;
    fourBitLookup[11] = 8;
    fourBitLookup[3] = 9;
    fourBitLookup[9] = 10;
    fourBitLookup[1] = 11;
    fourBitLookup[4] = 12;
    fourBitLookup[12] = 13;
    fourBitLookup[6] = 14;
    fourBitLookup[14] = 15;
    
    multi_uart_rx_port_init( rx_ports );
    
    /* initialisation loop */
    for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
    {
        state[i] = idle;
        uart_word[i] = 0;
        last_bit_val[i] = 0;
        bit_count[i] = 0;
        tickcount[i] = uart_rx_channel[i].use_sample;
    }
    
    mask = 0x01010101; // mask for desired bits - note, input word gets shifted, not the mask
    
    rx_ports.pUart :> port_val; // junk data
    while (1)
    {
        #pragma xta endpoint "rx_bit_ep"
        rx_ports.pUart :> port_val;
        
        #pragma loop unroll UART_RX_CHAN_COUNT
        for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
        {
            #pragma xta label "rx_bit_proc_loop"
            if (tickcount[i] < 4 || state[i] == idle)
            {
                word = port_val & mask;
                crc32( word, 0xf, 0xf );
                fourBits = fourBitLookup[word];
                bit = fourBits >> tickcount[i];
                bit &= 1;
                tick_adjustment = tickcount[i];
                
                switch (state[i])
                {
                case idle:
                    /* search for start bit edge */
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = data_bits;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit + uart_rx_channel[i].use_sample;
                        bit_count[i] = uart_rx_channel[i].uart_char_len;
                        uart_word[i] = 0;
                        break;
                    }
                    fourBits >>= 1;
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = data_bits;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit + uart_rx_channel[i].use_sample - 1;
                        bit_count[i] = uart_rx_channel[i].uart_char_len;
                        uart_word[i] = 0;
                        break;
                    }
                    fourBits >>= 1;
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = data_bits;
                        tick_adjustment = 1;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit + uart_rx_channel[i].use_sample - 2;
                        bit_count[i] = uart_rx_channel[i].uart_char_len;
                        uart_word[i] = 0;
                        break;
                    }
                    fourBits >>= 1;
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = data_bits;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit + uart_rx_channel[i].use_sample - 3;
                        bit_count[i] = uart_rx_channel[i].uart_char_len;
                        uart_word[i] = 0;
                        break;
                    }
                    break;
                case data_bits:
                    uart_word[i] <<= 1;
                    uart_word[i] |= bit;
                    bit_count[i]--;
                    if (bit_count[i] == 0) 
                    {
                            state[i] = stop_bit;
                    }
                    tickcount[i] = uart_rx_channel[i].clocks_per_bit - tick_adjustment;
                    break;
                case parity:
                    uart_word[i] <<= 1;
                    uart_word[i] |= bit;
                    state[i] = stop_bit;    
                    tickcount[i] = uart_rx_channel[i].clocks_per_bit - tick_adjustment;
                    break;
                case stop_bit:
                    if (bit == 1 && uart_rx_channel[i].nelements < UART_RX_BUF_SIZE) // TODO respect polarity
                    {
                        int wr_ptr = uart_rx_channel[i].wr_ptr;
                        uart_rx_channel[i].buf[wr_ptr] = uart_word[i];
                        wr_ptr++;
                        wr_ptr &= (UART_RX_BUF_SIZE-1);
                        uart_rx_channel[i].wr_ptr = wr_ptr;
                        uart_rx_channel[i].nelements++;
                    }
                    // TODO do IDLE check here in case there is a IPD of 1 bit?
                    state[i] = idle;
                    break;
                }
            } else tickcount[i] -= 4;
            /* shift input word for next channel */
            port_val >>= 1;
        }
        
    }
}

#if 0
#pragma xta command "analyze endpoints rx_bit_ep rx_bit_ep"
//#pragma xta command "set loop - rx_idle_loop 4"
#pragma xta command "set required - 4.34 us"
#pragma xta command "analyze function uart_rx_get_char"
#pragma xta command "print nodeinfo - -"
#endif
