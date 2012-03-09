#include <xs1.h>
#include <xccompat.h>
#include <print.h>
#include "multi_uart_helper.h"
#include "multi_uart_common.h"
#include "multi_uart_rxtx.h"
#include "echo_test.h"

volatile unsigned rx_buffer[8][ECHO_BUF_SIZE];
volatile unsigned rx_rd_ptr[8] = {0,0,0,0,0,0,0,0};
volatile unsigned rx_wr_ptr[8] = {0,0,0,0,0,0,0,0};
volatile unsigned rx_elements[8] = {0,0,0,0,0,0,0,0};

void uart_rxtx_echo_test( chanend cTxUART, chanend cRxBuf )
{

    unsigned uart_char, temp;
    unsigned baud_rate = 115200;
    
    printstr("Running echo test...\n");
    
    //:config_example
    /* configure UARTs */
    for (int i = 0; i < 8; i++)
    {
        if ((int)baud_rate <= 225)
            baud_rate = 225;
        
        if (uart_tx_initialise_channel( i, even, sb_1, baud_rate, 8 ))
        {
            printstr("Invalid baud rate for tx channel ");
            printintln(i);
        }
        
        if (uart_rx_initialise_channel( i, even, sb_1, start_0, baud_rate, 8 ))
        {
            printstr("Invalid baud rate for rx channel ");
            printintln(i);
        }
        
        printint(i); printstr(" => "); printint(baud_rate); printstr(" bps 8-E-1\n");
    }
    //:
    
    baud_rate /= 2;
    
    //:thread_start_helper_funcs
    /* release UART rx thread */
    do { temp = get_streaming_uint(cRxBuf); } while (temp != MULTI_UART_GO);
    send_streaming_int(cRxBuf, 1);
    
    /* release UART tx thread */
    do { temp = get_streaming_uint(cTxUART); } while (temp != MULTI_UART_GO);
    send_streaming_int(cTxUART, 1);
    //:
    
    /* main echo loop */
    while (1)
    {
        for (int i = 0; i < 8; i++)
        {
            if (rx_elements[i] > 0) // check if anything in buffer
            {
                uart_char = rx_buffer[i][rx_rd_ptr[i]];
                if (uart_tx_put_char(i, uart_char) != -1)
                {
                    rx_rd_ptr[i]++;
                    if (rx_rd_ptr[i] >= ECHO_BUF_SIZE)
                        rx_rd_ptr[i] = 0;
                    rx_elements[i]--;
                }
                else printstr("TX Buf Full\n");
                    
                // not built at the moment due to data errors occasionally causing this to trigger
                #if 0
                if ((char)uart_char == 'r')
                {
                    printstr("Reconfiguring...\n");
                
                    //:reconf_example
                    uart_tx_reconf_pause( cTxUART, t );
                    uart_rx_reconf_pause( cRxBuf );
                    
                    /* configure UARTs */
                    for (int i = 0; i < 8; i++)
                    {
                        if ((int)baud_rate <= 225)
                            baud_rate = 115200;
                        
                        if (uart_tx_initialise_channel( i, even, sb_1, baud_rate, 8 ))
                        {
                            printstr("Invalid baud rate for tx channel ");
                            printintln(i);
                        }
                        
                        if (uart_rx_initialise_channel( i, even, sb_1, start_0, baud_rate, 8 ))
                        {
                            printstr("Invalid baud rate for rx channel ");
                            printintln(i);
                        }
                        
                        printint(i); printstr(" => "); printint(baud_rate); printstr(" bps 8-E-1\n");
                    }
                    
                    baud_rate /= 2;
                    
                    uart_tx_reconf_enable( cTxUART );
                    uart_rx_reconf_enable( cRxBuf );
                    //:
                }
                #endif
            }
        }
    }
}

void rx_buffering( chanend cRxUART, chanend cRxBuf )
{
    unsigned chan_id = 0;
    unsigned uart_char, temp;
    int rv;
    
    do { uart_char = get_streaming_uint(cRxUART); } while (uart_char != MULTI_UART_GO);
    send_streaming_int(cRxBuf, uart_char); // pass up
    
    uart_char = get_streaming_uint(cRxBuf); 
    send_streaming_int(cRxUART, 1); // pass down
    
    printstr("RX Buf running\n");
    
    //:rx_echo_example
    while (1)
    {
        chan_id = (unsigned)get_streaming_token(cRxUART);
        
        /* get character over channel */
        uart_char = (unsigned)uart_rx_grab_char(chan_id);
        
        temp = uart_char;
        
        /* process received value */
        if ((rv = uart_rx_validate_char( chan_id, &uart_char )) == 0)
        {
            if (rx_elements[chan_id] < ECHO_BUF_SIZE)
            {
                rx_buffer[chan_id][rx_wr_ptr[chan_id]] = uart_char;
                rx_wr_ptr[chan_id]++;
                if (rx_wr_ptr[chan_id] >= ECHO_BUF_SIZE)
                    rx_wr_ptr[chan_id] = 0;
                rx_elements[chan_id]++;
                
            } else printstr("RX Buf Full\n");
        }
        else { printstr("RX Validation fail\n\t0x"); printhex(temp);printstr("\n\t");printintln(rv); }
    }
    //:
}

