#include "multi_uart_rx.h"
#include <print.h>

#if (UART_RX_CLOCK_DIVIDER/(2*UART_RX_OVERSAMPLE)) > 255
    #error "UART RX Divider is to big - max baud rate may be too low or ref freq too high"
#endif

extern s_multi_uart_rx_channel uart_rx_channel[UART_RX_CHAN_COUNT];

extern unsigned rx_char_slots[UART_RX_CHAN_COUNT];

#define increment(a, inc)  { a = (a+inc); a *= !(a == UART_RX_BUF_SIZE); }

static unsigned crc8_helper( unsigned &checksum, unsigned data, unsigned poly )
{
    return crc8shr(checksum, data, poly);
}

void multi_uart_rx_port_init( s_multi_uart_rx_ports &rx_ports, clock uart_clock )
{
    
    if (UART_RX_CLOCK_DIVIDER > 1)
    {
        configure_clock_ref( uart_clock, UART_RX_CLOCK_DIVIDER/(2*UART_RX_OVERSAMPLE));	
    }
    
    configure_in_port(	rx_ports.pUart, uart_clock); 
    
    start_clock( uart_clock );
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

void uart_rx_loop_8( in buffered port:32 pUart, e_uart_rx_chan_state state[], int tick_count[], int bit_count[], int uart_word[], streaming chanend cUART, unsigned rx_char_slots[]  );

// global for access by ASM
unsigned fourBitLookup[16];
unsigned startBitLookup[16];

#pragma unsafe arrays
void run_multi_uart_rx( streaming chanend cUART, s_multi_uart_rx_ports &rx_ports, clock uart_clock )
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
    startBitLookup[0b0000] = 4;
    startBitLookup[0b0001] = 3;
    startBitLookup[0b0011] = 2;
    startBitLookup[0b0111] = 1;
    
    multi_uart_rx_port_init( rx_ports, uart_clock );
    
    while (1)
    {
        
        cUART <: MULTI_UART_GO;
        cUART :> int _;
        
        /* initialisation loop */
        for (int i = 0; i < UART_RX_CHAN_COUNT; i++)
        {
            state[i] = idle;
            uart_word[i] = 0;
            bit_count[i] = 0;
            tickcount[i] = uart_rx_channel[i].use_sample;
        }
        
        rx_ports.pUart :> port_val; // junk data
        
        /* run ASM function - will exit on reconfiguration request over the channel */
        uart_rx_loop_8( rx_ports.pUart, state, tickcount, bit_count, uart_word, cUART, rx_char_slots );
    }
}


// Validate timing to 115200 baud
#if 0
#pragma xta command "echo --------------------------------------------------"
#pragma xta command "echo FullRxLoop"
#pragma xta command "analyze endpoints rx_bit_ep rx_bit_ep"
#pragma xta command "print nodeinfo - -"
#pragma xta command "set required - 8.68 us"

#pragma xta command "echo --------------------------------------------------"
#pragma xta command "analyze function uart_rx_validate_char"
#pragma xta command "print nodeinfo - -"


#pragma xta command "echo --------------------------------------------------"
#pragma xta command "echo Idle-idle_process_0-1"
#pragma xta command "analyze endpoints idle_process_0 idle_process_1"
#pragma xta command "print nodeinfo - -"
//#pragma xta command "set required - 1.085 us"

#pragma xta command "echo --------------------------------------------------"
#pragma xta command "echo Data-data_process_0-data_process_1"
#pragma xta command "analyze endpoints data_process_0 data_process_1"
#pragma xta command "print nodeinfo - -"
//#pragma xta command "set required - 1.085 us"
#endif





