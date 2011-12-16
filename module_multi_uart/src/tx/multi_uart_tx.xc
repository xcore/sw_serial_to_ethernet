#include "multi_uart_tx.h"
#include <print.h>

#if UART_TX_CLOCK_DIVIDER/(2*UART_TX_OVERSAMPLE) > 255
    #error "UART TX Divider / oversample combination producers divider that is too large"
#endif

#define PORT_TS_INC 1

extern s_multi_uart_tx_channel uart_tx_channel[UART_TX_CHAN_COUNT];

#define increment(a, inc)  { a = (a+inc); a *= !(a == UART_TX_BUF_SIZE); }

unsigned crc8_helper( unsigned &checksum, unsigned data, unsigned poly )
{
    return crc8shr(checksum, data, poly);
}

void multi_uart_tx_port_init( s_multi_uart_tx_ports &tx_ports )
{
    if (UART_TX_CLOCK_DIVIDER > 1)
    {
        // TODO configuration for external clock
        configure_clock_ref( tx_ports.cbUart, UART_TX_CLOCK_DIVIDER/(2*UART_TX_OVERSAMPLE) );	
    }
    
    configure_out_port(	tx_ports.pUart, tx_ports.cbUart, 0xFF); // TODO honour stop bit polarity
    
    start_clock( tx_ports.cbUart );
}

#pragma unsafe arrays
unsigned multi_uart_tx_buffer_get( int chan_id )
{
    unsigned word = 0;
    
    return word;
}

#pragma unsafe arrays
void run_multi_uart_tx( streaming chanend cUART, s_multi_uart_tx_ports &tx_ports )
{
    unsigned port_val = 0xFF; // TODO honour IDLE/STOP polarity
    unsigned short port_ts;
    int j = 0;
    
    unsigned current_word[UART_TX_CHAN_COUNT];
    unsigned current_word_pos[UART_TX_CHAN_COUNT];
    unsigned tick_count[UART_TX_CHAN_COUNT];
    unsigned clocks_per_bit[UART_TX_CHAN_COUNT];
    
    multi_uart_tx_port_init( tx_ports );
    
	cUART <: MULTI_UART_GO;
	cUART :> int _;
	
	/* initialise data structures */
	for (int i = 0; i < UART_TX_CHAN_COUNT; i++)
	{
	    current_word[i] = 0;
		current_word_pos[i] = 0; // disable channel
		tick_count[i] = 0;
		uart_tx_channel[i].wr_ptr = 0;
		uart_tx_channel[i].rd_ptr = 0;
		uart_tx_channel[i].nelements = 0;
		clocks_per_bit[i] = uart_tx_channel[i].clocks_per_bit;
	}
	
	port_val = 0xffffffff;
	/* initialise port */
	tx_ports.pUart <: port_val @ port_ts;
	port_ts += 20;

	while (1)
	{
		/* process the next bit on the ports */
		#pragma xta endpoint "tx_bit_ep"
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
			    port_val ^= (current_word[i] & 1) << i;
				current_word[i] >>= 1;
				current_word_pos[i] -= 1;
				tick_count[i] = clocks_per_bit[i];
			} 
		}
		
		/* check if UART channel needs a value from the buffer */
		if (current_word_pos[j] == 0 && uart_tx_channel[j].nelements)
		{
		    int rd_ptr = uart_tx_channel[j].rd_ptr;
		    current_word[j] = uart_tx_channel[j].buf[rd_ptr];
		    rd_ptr++;
		    rd_ptr &= (UART_TX_BUF_SIZE-1);
		    uart_tx_channel[j].rd_ptr = rd_ptr;
		    uart_tx_channel[j].nelements--;
		    current_word_pos[j] = uart_tx_channel[j].uart_word_len;
		    tick_count[j] = clocks_per_bit[j];
		}
		
		j++;
		j &= (UART_TX_CHAN_COUNT-1);
    }   
}

/* do timing for loop - 4.35uS is 230500bps */
#pragma xta command "echo --------------------------------------------------"
#pragma xta command "analyze endpoints tx_bit_ep tx_bit_ep"
#pragma xta command "set required - 4.34 us"
#pragma xta command "analyze function uart_tx_put_char"
#pragma xta command "print nodeinfo - -"
#pragma xta command "echo --------------------------------------------------"
