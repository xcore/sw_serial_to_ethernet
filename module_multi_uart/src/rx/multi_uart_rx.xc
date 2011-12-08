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
    idle = 0x0,
    store_idle,
    data_bits = 0x1,
} e_uart_rx_chan_state;

void uart_rx_loop( in buffered port:32 pUart, e_uart_rx_chan_state state[], int tick_count[], int bit_count[], int uart_word[], streaming chanend cUART  );

// global for access by ASM
unsigned fourBitLookup[16];
unsigned startBitLookup[16];

#pragma unsafe arrays
void run_multi_uart_rx( streaming chanend cUART, s_multi_uart_rx_ports &rx_ports )
{

    unsigned port_val;
    e_uart_rx_chan_state state[UART_RX_CHAN_COUNT];
    unsigned word, fourBits, bit;
    int tc;
    
    int tickcount[UART_RX_CHAN_COUNT];
    int bit_count[UART_RX_CHAN_COUNT];
    int uart_word[UART_RX_CHAN_COUNT];
    
    /*
     * Four bit look up table that takes the CRC32 with poly 0xf of the masked off 32 bit word 
     * from an 8 bit port and translates it into the 4 desired bits - huzzah!
     */
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
    
    for (int i = 0; i < 16; i++)
    {
        startBitLookup[i] = 0xffffffff;
    }
    startBitLookup[0b0000] = 0;
    startBitLookup[0b0001] = 1;
    startBitLookup[0b0011] = 2;
    startBitLookup[0b0111] = 3;
    
    multi_uart_rx_port_init( rx_ports );
    
    /* initialisation loop */
    for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
    {
        state[i] = idle;
        uart_word[i] = 0;
        bit_count[i] = 0;
        tickcount[i] = uart_rx_channel[i].use_sample;
    }
    
    rx_ports.pUart :> port_val; // junk data
    while (1)
    {
        
        uart_rx_loop( rx_ports.pUart, state, tickcount, bit_count, uart_word, cUART  );
        
        #if 0
        #endif
        
    }
}

#if 0
#pragma xta command "config Terror off"
#pragma xta command "analyze endpoints rx_bit_ep rx_bit_ep"
#pragma xta command "set loop - process_loop 8"
#pragma xta command "set loop - rx_bit_ep 1"
//#pragma xta command "print nodeinfo - -"
#pragma xta command "set required - 4.34 us"


#pragma xta command "analyze function uart_rx_get_char"
#pragma xta command "print nodeinfo - -"
#endif
