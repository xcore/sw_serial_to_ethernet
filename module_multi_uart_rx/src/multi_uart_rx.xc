#include "multi_uart_rx.h"
#include <print.h>

#define PORT_TS_INC 1

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
    if (uart_rx_channel[chan_id].nelements < UART_RX_BUF_SIZE)
    {
        int wr_ptr = uart_rx_channel[chan_id].wr_ptr;
        uart_rx_channel[chan_id].buf[wr_ptr] = uart_word;
        wr_ptr++;
        wr_ptr &= (UART_RX_BUF_SIZE-1);
        uart_rx_channel[chan_id].wr_ptr = wr_ptr;
        uart_rx_channel[chan_id].nelements++;
    }
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

    /*
     * Four bit look up table that takes the CRC32 with poly 0xf of the masked off 32 bit word 
     * from an 8 bit port and translates it into the 4 desired bits - huzzah!
     */
    unsigned fourBitLookup[16] = 
    {
        0b0100,
        0b1011,
        0b0110,
        0b1001,
        0b1100,
        0b0011,
        0b1110,
        0b0001,
        0b0101,
        0b1010,
        0b0111,
        0b1000,
        0b1101,
        0b0010,
        0b1111,
        0b0000,
    };
    
    unsigned port_val;
    e_uart_rx_chan_state state[UART_RX_CHAN_COUNT];
    unsigned mask, word, fourBits, bit;
    int tick_adjustment;
    
    int tickcount[UART_RX_CHAN_COUNT];
    int bit_count[UART_RX_CHAN_COUNT];
    int last_bit_val[UART_RX_CHAN_COUNT];
    int uart_word[UART_RX_CHAN_COUNT];
    
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
    
    rx_ports.pUart :> port_val; // junk data
    while (1)
    {
        #pragma xta endpoint "rx_bit_ep"
        rx_ports.pUart :> port_val;
        
        mask = 0x01010101; // mask for desired bits - note, input word gets shifted, not the mask
        
        #pragma loop unroll UART_RX_CHAN_COUNT
        for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
        {
            #pragma xta label "rx_bit_proc_loop"
            
            if (tickcount[i] < 4 || state[i] == idle)
            {
                word = port_val & mask;
                crc32( word, 0xf, 0xf );
                fourBits = fourBitLookup[word];
                bit = fourBits & (1 << tickcount[i]);
                bit >>= tickcount[i];
                tick_adjustment = 3 - tickcount[i];
                
                switch (state[i])
                {
                case idle:
                    /* search for start bit edge */
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = start_bit;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].use_sample - 3;
                        break;
                    }
                    fourBits >>= 1;
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = start_bit;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].use_sample - 2;
                        break;
                    }
                    fourBits >>= 1;
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = start_bit;
                        tick_adjustment = 1;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].use_sample - 1;
                        break;
                    }
                    fourBits >>= 1;
                    if ((fourBits & 1) == 0) // TODO polarity
                    {
                        state[i] = start_bit;
                        /* align us with the centre of the bit */
                        tickcount[i] = uart_rx_channel[i].use_sample;
                        break;
                    }
                    break;
                case start_bit:
                    if (bit == 0) // TODO polarity
                    {
                        state[i] = data_bits;
                        bit_count[i] = uart_rx_channel[i].uart_char_len;
                        uart_word[i] = 0;
                    }
                    tickcount[i] = uart_rx_channel[i].clocks_per_bit - tick_adjustment;
                    break;
                case data_bits:
                    uart_word[i] <<= 1;
                    uart_word[i] |= bit;
                    bit_count[i]--;
                    if (bit_count[i] == 0) // TODO respect parity setting
                        state[i] = parity;
                    tickcount[i] = uart_rx_channel[i].clocks_per_bit - tick_adjustment;
                    break;
                case parity:
                    uart_word[i] <<= 1;
                    uart_word[i] |= bit;
                    state[i] = stop_bit;
                    tickcount[i] = uart_rx_channel[i].clocks_per_bit - tick_adjustment;
                    break;
                case stop_bit:
                    if (bit == 1) // TODO respect polarity
                        multi_uart_rx_buffer_put( i, uart_word[i] );
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


#pragma xta command "analyze endpoints rx_bit_ep rx_bit_ep"
//#pragma xta command "set loop - rx_idle_loop 4"
#pragma xta command "set required - 4.34 us" // timing requirement per bit is this value over 4
//#pragma xta command "print summary"
