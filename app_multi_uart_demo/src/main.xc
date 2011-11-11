#include <xs1.h>
#include <platform.h>
#include <print.h>
#include "multi_uart_tx.h"

s_multi_uart_tx_ports uart_tx_ports =
{    
    XS1_PORT_8A,
    XS1_PORT_1A,
    XS1_CLKBLK_REF
};


void uart_tx_test(chanend cUART)
{
    unsigned char char_tx = 0x0;
    unsigned temp = 0;

    /* configure UARTs */
    for (int i = 0; i < 8; i++)
    {
       if (uart_tx_initialise_channel( i, even, sb_1, 50000, 8 ))
       {
           printstr("Invalid baud rate for channel ");
           printintln(i);
       }
    }
   
   while (temp != UART_TX_GO)
   {
       cUART <: UART_TX_GO;
       cUART :> temp;
   }
   
   while (1)
   {
       for (int i = 0; i < 8;)
       {
           int buffer_space;
           cUART <: i;
           cUART <: char_tx;
           cUART :> buffer_space;
           if (buffer_space)
               i++;
       }
       char_tx += 1;
   }
}

/**
 * Top level main for multi-UART demonstration
 */
int main(void)
{
    chan cUART;
    
    par
    {
        uart_tx_test(cUART);
        run_multi_uart_tx( cUART, uart_tx_ports );
    }
    return 0;
}
