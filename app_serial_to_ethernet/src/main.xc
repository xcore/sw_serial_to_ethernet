// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include <xs1.h>
#include "uip_server.h"
#include "getmac.h"
#include <print.h>
#include <xscope.h>
#include <flash.h>
#include "uip_single_server.h"
#include "multi_uart_rxtx.h"
#include "tcp_handler.h"
#include "uart_handler.h"
#include "s2e_flash.h"

#define ETH_CORE 0
#define UART_CORE 1

// Ethernet Ports
on stdcore[ETH_CORE]: struct otp_ports otp_ports =
{
  XS1_PORT_32B,
  XS1_PORT_16C,
  XS1_PORT_16D
};


#define PORT_ETH_FAKE on stdcore[ETH_CORE]: XS1_PORT_8C

on stdcore[ETH_CORE]: mii_interface_t mii =
{
	XS1_CLKBLK_2,
	XS1_CLKBLK_3,

	PORT_ETH_RXCLK_1,
	PORT_ETH_ERR_1,
	PORT_ETH_RXD_1,
	PORT_ETH_RXDV_1,

	PORT_ETH_TXCLK_1,
	PORT_ETH_TXEN_1,
	PORT_ETH_TXD_1,
    PORT_ETH_FAKE
};

#define PORT_ETH_RST_N XS1_PORT_8D

on stdcore[ETH_CORE]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[ETH_CORE]: smi_interface_t smi = {0, PORT_ETH_MDIO_1, PORT_ETH_MDC_1};

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
  XS1_CLKBLK_1
};

fl_DeviceSpec flash_devices[] =
{
 FL_DEVICE_NUMONYX_M25P16,
};


void xscope_user_init(void) {
  xscope_register(0);
  xscope_config_io(XSCOPE_IO_BASIC);
}


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
            char mac_address[6];
            xtcp_ipconfig_t ipconfig;
            c_xtcp[0] :> ipconfig;

            ethernet_getmac_otp(otp_ports, mac_address);
            // Start server
            uip_single_server(null, smi, mii, c_xtcp, 1,
                              ipconfig, mac_address);
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
