#include "multi_uart_rx.h"
#include "multi_uart_tx.h"
#include "multi_uart_rx_conf.h"
#include "multi_uart_tx_conf.h"

void multi_uart_common_setup_external_clock( in port ext_ref_clk_pin, clock uart_clk )
{
    configure_clock_src(uart_clk, ext_ref_clk_pin);
    
}

void run_multi_uart_rxtx( streaming chanend cTxUart, s_multi_uart_tx_ports &uart_tx_ports, streaming chanend cRxUart, s_multi_uart_rx_ports &uart_rx_ports, clock uart_clock_rx, in port uart_ext_clk_pin, clock uart_clock_tx)
{
    multi_uart_common_setup_external_clock( uart_ext_clk_pin, uart_clock_tx );
    
    par
    {
        run_multi_uart_tx( cTxUart, uart_tx_ports, uart_clock_tx );
        run_multi_uart_rx( cRxUart, uart_rx_ports, uart_clock_rx );
    }
}

void run_multi_uart_rxtx_int_clk( streaming chanend cTxUart, s_multi_uart_tx_ports &uart_tx_ports, streaming chanend cRxUart, s_multi_uart_rx_ports &uart_rx_ports, clock uart_clock_rx, clock uart_clock_tx)
{
    par
    {
        run_multi_uart_tx( cTxUart, uart_tx_ports, uart_clock_tx );
        run_multi_uart_rx( cRxUart, uart_rx_ports, uart_clock_rx );
    }
}
