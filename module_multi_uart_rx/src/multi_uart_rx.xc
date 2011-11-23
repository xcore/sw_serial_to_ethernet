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
        configure_clock_ref( rx_ports.cbUart, UART_RX_CLOCK_DIVIDER/2 );	
    }
    
    configure_out_port(	rx_ports.pUart, rx_ports.cbUart, 1); // TODO honour stop bit polarity
    
    start_clock( rx_ports.cbUart );
}

#pragma unsafe arrays
unsigned multi_uart_rx_buffer_put( int chan_id, unsigned int uart_word )
{
    unsigned word = 0;
    
    return word;
}


typedef enum ENUM_UART_RX_CHAN_STATE
{
    idle,
    start_bit,
    data_bit_0,
    data_bits,
    parity_0,
    parity,
    stop_bit_0,
    stop_bit    
} e_uart_rx_chan_state;

#pragma unsafe arrays
void run_multi_uart_rx( streaming chanend cUART, s_multi_uart_rx_ports &rx_ports )
{

    unsigned port_val;
    e_uart_rx_chan_state state[UART_RX_CHAN_COUNT];
    
    unsigned tickcount[UART_RX_CHAN_COUNT];
    unsigned bit_count[UART_RX_CHAN_COUNT];
    unsigned last_bit_val[UART_RX_CHAN_COUNT];
    unsigned uart_word[UART_RX_CHAN_COUNT];
    
    multi_uart_rx_port_init( rx_ports );
    
    /* initialisation loop */
    for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
    {
        state[i] = start_bit;
        uart_word[i] = 0;
        last_bit_val[i] = 0;
        bit_count[i] = 0;
        tickcount[i] = uart_rx_channel[i].clocks_per_bit;
    }
    
    while (1)
    {
        #pragma xta endpoint "rx_bit_ep"
        rx_ports.pUart :> port_val;
        
        #pragma loop unroll UART_RX_CHAN_COUNT
        for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
        {
            #pragma xta label "rx_bit_proc_loop"
            unsigned bit = port_val & 1;
            
            switch (state[i])
            {
                case start_bit:
                    if (bit == 0) // TODO respect polarity ??
                    {
                        tickcount[i]--;
                        if (tickcount[i] == 0)
                        {
                            state[i] = data_bit_0;
                            tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                            bit_count[i] = uart_rx_channel[i].uart_char_len;
                            uart_word[i] = 0;
                        }
                        else state[i] = start_bit;
                    }
                    else tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                    break;
                case data_bit_0:
                    last_bit_val[i] = bit;
                    tickcount[i]--;
                    if (tickcount[i] == 0) /* this only occurs if clks per bit is 1 */
                    {
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                        uart_word[i] <<= 1;
                        uart_word[i] |= bit;
                        bit_count[i]--;
                        if (bit_count[i] == 0)
                            state[i] = parity_0;
                        else
                            state[i] = data_bit_0;
                    } else state[i] = data_bits;
                    break;
                case data_bits:
                    if (last_bit_val[i] == bit)
                    {
                        tickcount[i]--;
                        if (tickcount[i] == 0) /* this only occurs if clks per bit is 1 */
                        {
                            tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                            uart_word[i] <<= 1;
                            uart_word[i] |= bit;
                            bit_count[i]--;
                            if (bit_count[i] == 0)
                                state[i] = parity_0;
                            else
                                state[i] = data_bit_0;
                        }
                    }
                    else
                    {
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                        state[i] = start_bit;
                    }
                    last_bit_val[i] = bit;
                    break;
                case parity_0:
                    last_bit_val[i] = bit;
                    tickcount[i]--;
                    if (tickcount[i] == 0) /* this only occurs if clks per bit is 1 */
                    {
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                        uart_word[i] <<= 1;
                        uart_word[i] |= bit;
                        state[i] = stop_bit;
                    } else
                        state[i] = parity;
                    break;
                case parity:
                    if (last_bit_val[i] == bit)
                    {
                        tickcount[i]--;
                        if (tickcount[i] == 0) /* this only occurs if clks per bit is 1 */
                        {
                            tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                            uart_word[i] <<= 1;
                            uart_word[i] |= bit;
                            state[i] = stop_bit;
                        } else
                            state[i] = parity;
                    }
                    else
                    {
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                        state[i] = start_bit;
                    }
                    last_bit_val[i] = bit;
                    break;
                case stop_bit:
                    // TODO handle multiple stop bits
                    // TODO push into buffer
                    if (bit == 1) // TODO respect polarity
                    {
                        tickcount[i]--;
                        if (tickcount[i] == 0)
                        {
                            if (uart_rx_channel[i].nelements < UART_RX_BUF_SIZE)
                            {
                                int wr_ptr = uart_rx_channel[i].wr_ptr;
                                uart_rx_channel[i].buf[wr_ptr] = uart_word[i];
                                wr_ptr++;
                                wr_ptr &= (UART_RX_BUF_SIZE-1);
                                uart_rx_channel[i].wr_ptr = wr_ptr;
                                uart_rx_channel[i].nelements++;
                            }
                            tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                            state[i] = start_bit;
                        } else
                            state[i] = stop_bit;
                    }
                    else
                    {
                        tickcount[i] = uart_rx_channel[i].clocks_per_bit;
                        state[i] = start_bit;
                    }
                    break;
            }
            port_val >>= 1;
        }
        
    }
}


#pragma xta command "analyze endpoints rx_bit_ep rx_bit_ep"
#pragma xta command "set required - 4.34 us"
//#pragma xta command "print summary"
