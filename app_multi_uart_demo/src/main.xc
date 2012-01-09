#include <xs1.h>
#include <platform.h>
#include <print.h>
#include "multi_uart_common.h"
#include "multi_uart_rxtx.h"

s_multi_uart_tx_ports uart_tx_ports =
{    
    XS1_PORT_8A,
};

s_multi_uart_rx_ports uart_rx_ports =
{    
    XS1_PORT_8B,
};

in port uart_ref_ext_clk = XS1_PORT_1A;
clock uart_clock = XS1_CLKBLK_1;


void uart_tx_test(streaming chanend cUART)
{
    char test_str[8][29] = {"UART Channel 1 Test String\n\0",
        "UART Channel 2 Test String\n\0",
        "UART Channel 3 Test String\n\0",
        "UART Channel 4 Test String\n\0",
        "UART Channel 5 Test String\n\0",
        "UART Channel 6 Test String\n\0",
        "UART Channel 7 Test String\n\0",
        "UART Channel 8 Test String\n\0"};
        
    
    unsigned rd_ptr[8] = {0,0,0,0,0,0,0,0};
    unsigned temp = 0;
    int chan_id = 0;
    unsigned baud_rate = 115200;
    int buffer_space = 0;
    
    timer t;

    /* configure UARTs */
    for (int i = 0; i < 8; i++)
    {
        if ((int)baud_rate <= 225)
           baud_rate = 225;
       
       printintln(baud_rate);
       
       if (uart_tx_initialise_channel( i, none, sb_1, baud_rate, 8 ))
       {
           printstr("Invalid baud rate for tx channel ");
           printintln(i);
       }
       //baud_rate >>= 1;
    }
   
   while (temp != MULTI_UART_GO)
   {
       cUART :> temp;
   }
   cUART <: 1;

   while (1)
   {
       /* fill buffers with test strings */
       buffer_space = uart_tx_put_char(chan_id, (unsigned int)test_str[chan_id][rd_ptr[chan_id]]);
       
       if (buffer_space != -1)
       {
           if (rd_ptr[chan_id] == 28)
               rd_ptr[chan_id] = 0;
           else
               rd_ptr[chan_id]++;
       }
       chan_id++;
       chan_id &= UART_TX_CHAN_COUNT-1;
       
       #if 0
       /* test reconfiguration */
       if (test_count > 1000)
       {
           
           uart_tx_reconf_pause( cUART, t );
           
           /* reset counter */
           test_count = 0;
           
           /* configure UARTs */
           baud_rate /= 2;
           if ((int)baud_rate <= 225)
               baud_rate = 225;
           for (int i = 0; i < 8; i++)
           {
               printintln(baud_rate);
               if (uart_tx_initialise_channel( i, even, sb_1, baud_rate, 8 ))
               {
                   printstr("Invalid baud rate for tx channel ");
                   printintln(i);
               }
           }
           
           uart_tx_reconf_enable( cUART );
           
       }
       #endif
   }
}

void uart_rx_test(streaming chanend cUART)
{
    unsigned uart_char, temp;
    unsigned baud_rate = 100000; 
    
    /* configure UARTs */
    for (int i = 0; i < 8; i++)
    {
        if (uart_rx_initialise_channel( i, even, sb_1, start_0, baud_rate, 8 ))
        {
            printstr("Invalid baud rate for rx channel ");
            printintln(i);
        }
        baud_rate /= 2;
        if ((int)baud_rate <= 3125)
            baud_rate = 3125;
    }
    
    /* wait for intialisation */
    while (temp != MULTI_UART_GO) cUART :> temp;
    cUART <: 1;
    
    /* main loop */
    while (1)
    {
        int chan_id;
        
        /* get character over channel */
        cUART :>  chan_id;
        cUART :> uart_char;
        
        /* process received value */
        temp = uart_char;
        
        
        for (int i = 0; i < chan_id; i++)
            printchar('\t');
        
        /* validation of uart char - gives you the raw character as well */
        if (uart_rx_validate_char( chan_id, uart_char ) == 0)
        {
            printint(chan_id); printstr(": "); printhex(temp); printstr(" -> ");
            printhexln(uart_char);
        }
        else 
        {
            printint(chan_id); printstr(": "); printhex(temp); printstr(" -> ");
            printhex(uart_char);
            printstr(" [IV]\n");
        }
    }
}

void dummy()
{
    while (1);
}

/**
 * Top level main for multi-UART demonstration
 */
int main(void)
{
    streaming chan cTxUART;
    streaming chan cRxUART;
    
    par
    {
        /* use all 8 threads */
        dummy();
        dummy();
        dummy();
        dummy();
        
        /* TX Stuff */
        uart_tx_test(cTxUART);
        
        
        /* RX stuff */
        //uart_rx_test(cRxUART);
        
        /* run the multi-uart RX & TX with a common external clock */
        run_ext_clk_multi_uart_rxtx( cTxUART,  uart_tx_ports, cRxUART, uart_rx_ports, uart_ref_ext_clk, uart_clock);
    }
    return 0;
}
