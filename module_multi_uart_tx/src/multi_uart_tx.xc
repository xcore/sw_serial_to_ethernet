#include "multi_uart_tx.h"
#include <print.h>

#define PORT_TS_INC 1

extern s_multi_uart_tx_channel uart_tx_channel[UART_TX_CHAN_COUNT];

#define increment(a, inc)  { a = (a+inc); a *= !(a == UART_TX_BUF_SIZE); }

unsigned crc8_helper( unsigned &checksum, unsigned data, unsigned poly )
{
    return crc8shr(checksum, data, poly);
}

void multi_uart_tx_port_init( s_multi_uart_tx_ports &tx_ports )
{
    if (UART_CLOCK_DIVIDER > 1)
    {
        // TODO configuration for external clock
        configure_clock_ref( tx_ports.cbUart, UART_CLOCK_DIVIDER/2 );	
    }
    
    configure_out_port(	tx_ports.pUart, tx_ports.cbUart, 1); // TODO honour stop bit polarity
    
    start_clock( tx_ports.cbUart );
}

#pragma unsafe arrays
unsigned multi_uart_tx_buffer_get( int chan_id )
{
    unsigned word = 0;
    
    int rd_ptr = uart_tx_channel[chan_id].rd_ptr;
    uart_tx_channel[chan_id].nelements++;
    uart_tx_channel[chan_id].buf_empty = 
        (uart_tx_channel[chan_id].nelements == uart_tx_channel[chan_id].nMax);
        
    for (int i = 0; i < uart_tx_channel[chan_id].inc; i++)
    {
        #pragma xta label "buffer_get"
        word |= (uart_tx_channel[chan_id].buf[rd_ptr]) << (8*i);
        rd_ptr++;
        rd_ptr *= !(rd_ptr == UART_TX_BUF_SIZE);
    }
    uart_tx_channel[chan_id].rd_ptr = rd_ptr;
    
    return word;
}

{unsigned, unsigned} multi_uart_tx_chan_get( int chan_id, chanend cUART )
{
    
    int t;
    unsigned uart_word;
    unsigned status = 1;
    
   select
   {
   case cUART :> t:
       cUART :> uart_word;
       status = (chan_id != t); 
       cUART <: status;
       break;
   default:
       break;
   }
    
    return {uart_word, status};                           
}

#pragma unsafe arrays
int multi_uart_tx_buffer_put( int chan_id, char data[] )
{
    /* push data into the buffer */
    if (uart_tx_channel[chan_id].nelements) // buffer has space
    {
        int wr_ptr = uart_tx_channel[chan_id].wr_ptr;
        uart_tx_channel[chan_id].nelements--;
        
        for (int i = 0; i < uart_tx_channel[chan_id].inc; i++)
        {
			#pragma xta label "buffer_put"
            uart_tx_channel[chan_id].buf[wr_ptr] = data[i];
            wr_ptr++;
            wr_ptr *= !(wr_ptr == UART_TX_BUF_SIZE);
        }
        uart_tx_channel[chan_id].wr_ptr = wr_ptr;
        uart_tx_channel[chan_id].buf_empty = 0;
    }
    
    return uart_tx_channel[chan_id].nelements;
}

#pragma unsafe arrays
void run_multi_uart_tx( streaming chanend cUART, s_multi_uart_tx_ports &tx_ports )
{
    int chan_id;
    unsigned uart_word;
    int elements_available;
    unsigned run_tx_loop = 0;
    unsigned port_val = 0xFF; // TODO honour IDLE/STOP polarity
    unsigned short port_ts;
    
    unsigned current_word[UART_TX_CHAN_COUNT];
    unsigned current_word_pos[UART_TX_CHAN_COUNT];
    unsigned tick_count[UART_TX_CHAN_COUNT];
    
    multi_uart_tx_port_init( tx_ports );
    
	cUART <: UART_TX_GO;
	
	/* initialise data structures */
	for (int i = 0; i < UART_TX_CHAN_COUNT; i++)
	{
	    current_word[i] = 0;
		current_word_pos[i] = 0; // disable channel
		tick_count[i] = 0;
		uart_tx_channel[i].wr_ptr = 0;
		uart_tx_channel[i].rd_ptr = 0;
		uart_tx_channel[i].nelements = uart_tx_channel[i].nMax;

		current_word[i] = 0xAAAA;
		current_word_pos[i] = uart_tx_channel[i].uart_word_len;
		tick_count[i] = uart_tx_channel[i].clocks_per_bit;
	}
    
	port_val = 0xffffffff;
	/* initialise port */
	tx_ports.pUart <: port_val @ port_ts;
	port_ts += 20;

	while (1)
	{
		/* process the next bit on the ports */
		#pragma xta endpoint "bit_ep"
		tx_ports.pUart @ port_ts <: port_val;
		port_ts += PORT_TS_INC;

		/* calculate next port_val */
		#pragma loop unroll UART_TX_CHAN_COUNT
		for (int i = 0; i < UART_TX_CHAN_COUNT; i++)
		{
		    #pragma xta label "update_loop"
			tick_count[i]--;
		    /* active and counter tells us we need to send a bit */
			if (tick_count[i] == 0 && current_word_pos[i])
			{
				port_val &= ~(1 << i);
			    port_val |= (current_word[i] & 1) << i;
				current_word[i] >>= 1;
				current_word_pos[i] -= 1;
				tick_count[i] = uart_tx_channel[i].clocks_per_bit;
			} 
		}
		
		/* check if otherside trying to send a value */
		select
		{
		case cUART :> chan_id:
		    cUART :> uart_word;
		    if (!current_word_pos[chan_id])
		    {
		        current_word[chan_id] = uart_word;
		        current_word_pos[chan_id] = uart_tx_channel[chan_id].uart_word_len;
		        tick_count[chan_id] = uart_tx_channel[chan_id].clocks_per_bit;
		        cUART <: 1;
		    } else
		        cUART <: 0;
		    break;
		default:
		    break;
		}
    }   
}
