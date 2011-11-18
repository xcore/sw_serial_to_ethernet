#include <xs1.h>
#include <platform.h>
#include <print.h>
#include "multi_uart_tx.h"

s_multi_uart_tx_ports uart_tx_ports =
{    
    XS1_PORT_8A,
    XS1_PORT_1A,
    XS1_CLKBLK_1
};


void uart_tx_test(streaming chanend cUART)
{
    unsigned char char_tx = 0xAA;
    unsigned temp = 0;
    unsigned baud_rate = 200000;

    /* configure UARTs */
    for (int i = 0; i < 8; i++)
    {
       if (uart_tx_initialise_channel( i, even, sb_1, baud_rate, 8 ))
       {
           printstr("Invalid baud rate for channel ");
           printintln(i);
       }
       printintln(baud_rate);
       baud_rate /= 2;
       if ((int)baud_rate <= 3125)
           baud_rate = 3125;
       
    }
   
   while (temp != UART_TX_GO)
   {
       cUART :> temp;
   }
   cUART <: 1;

   while (1)
   {
       for (int i = 0; i < 8;)
       {
           int buffer_space = uart_tx_put_char(i, (unsigned int)char_tx);
           i += (buffer_space < UART_TX_BUF_SIZE);
       }
       char_tx += 1;
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
    streaming chan cUART;
    
    par
    {
        dummy();
        dummy();
        dummy();
        dummy();
        dummy();
        dummy();
        
        uart_tx_test(cUART);
        run_multi_uart_tx( cUART, uart_tx_ports );
    }
    return 0;
}
