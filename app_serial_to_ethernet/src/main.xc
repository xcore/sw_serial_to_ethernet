// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include <xs1.h>
#include "xtcp.h"
#include "ethernet_board_support.h"
#include <print.h>
#include <flash.h>
#include "multi_uart_rxtx.h"
#include "tcp_handler.h"
#include "uart_handler.h"
#include "s2e_flash.h"

#define ETH_CORE 0
#define UART_CORE 0

ethernet_xtcp_ports_t xtcp_ports =
  {    on stdcore[ETH_CORE]:  OTP_PORTS_INITIALIZER,
       ETHERNET_DEFAULT_SMI_INIT,
       ETHERNET_DEFAULT_MII_INIT_lite,
       ETHERNET_DEFAULT_RESET_INTERFACE_INIT};

#define PORT_TX on stdcore[UART_CORE]: XS1_PORT_8B
#define PORT_RX on stdcore[UART_CORE]: XS1_PORT_8A

s_multi_uart_tx_ports uart_tx_ports = { PORT_TX };
s_multi_uart_rx_ports uart_rx_ports = {	PORT_RX };

on stdcore[UART_CORE]: clock clk_uart_tx = XS1_CLKBLK_4;
on stdcore[UART_CORE]: in port p_uart_ref_ext_clk = XS1_PORT_1F; /* Define 1 bit external clock */
on stdcore[UART_CORE]: clock clk_uart_rx = XS1_CLKBLK_5;

on stdcore[0] : fl_SPIPorts flash_ports =
{ PORT_SPI_MISO,
  PORT_SPI_SS,
  PORT_SPI_CLK,
  PORT_SPI_MOSI,
  XS1_CLKBLK_3
};

fl_DeviceSpec flash_devices[] =
{
 FL_DEVICE_NUMONYX_M25P16,
};

// Program entry point
int main(void) {
	chan c_xtcp[1];
        chan c_uart_data, c_uart_config;
        chan c_flash_web, c_flash_data;
        streaming chan c_uart_rx, c_uart_tx;

	par
	{

        on stdcore[ETH_CORE]:
        {
            xtcp_ipconfig_t ipconfig;
            c_xtcp[0] :> ipconfig;
            // Start ethernet server
            ethernet_xtcp_server(xtcp_ports, ipconfig, c_xtcp, 1);
        }

        on stdcore[0]: s2e_flash(c_flash_web, c_flash_data, flash_ports);

        on stdcore[UART_CORE]: tcp_handler(c_xtcp[0], c_uart_data,
                                           c_uart_config,
                                           c_flash_web, c_flash_data);

        on stdcore[UART_CORE]: uart_handler(c_uart_data, c_uart_config,
                                            c_uart_rx, c_uart_tx);

        on stdcore[UART_CORE]: run_multi_uart_rxtx(c_uart_tx,uart_tx_ports,
                                           c_uart_rx,uart_rx_ports,
                                           clk_uart_rx, p_uart_ref_ext_clk,
                                           clk_uart_tx);

	}
	return 0;
}
