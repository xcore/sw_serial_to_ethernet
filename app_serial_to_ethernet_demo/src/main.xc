// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include "uip_server.h"
#include "getmac.h"
#include "ethernet_server.h"
#include <print.h>
#include "telnetd.h"
#include "app_manager.h"
#include "web_server.h"

#define PORT_TX_TEMP_1 on stdcore[1]: XS1_PORT_8A
#define PORT_TX_TEMP_2 on stdcore[1]: XS1_PORT_1A
#define PORT_TX_TEMP_3 on stdcore[1]: XS1_CLKBLK_1

#define PORT_RX_TEMP_1 on stdcore[1]: XS1_PORT_8B
#define PORT_RX_TEMP_2 on stdcore[1]: XS1_PORT_1B
#define PORT_RX_TEMP_3 on stdcore[1]: XS1_CLKBLK_2

#if 1
s_multi_uart_tx_ports uart_tx_ports =
{
	PORT_TX_TEMP_1,
	PORT_TX_TEMP_2,
	PORT_TX_TEMP_3
};

s_multi_uart_rx_ports uart_rx_ports =
{
	PORT_RX_TEMP_1,
	PORT_RX_TEMP_2,
	PORT_RX_TEMP_3
};
#else
on stdcore[3]: out port tx_port = XS1_PORT_8A;
on stdcore[3]: out port tx_port_clk = XS1_PORT_1A;
on stdcore[3]: out port tx_port_clk_src = XS1_CLKBLK_1;

on stdcore[3]: out port rx_port = XS1_PORT_8B;
on stdcore[3]: out port rx_port_clk = XS1_PORT_1B;
on stdcore[3]: out port rx_port_clk_src = XS1_CLKBLK_2;

s_multi_uart_tx_ports uart_tx_ports =
{
	tx_port,
	tx_port_clk,
	tx_port_clk_src
};

s_multi_uart_rx_ports uart_rx_ports =
{
	rx_port,
	rx_port_clk,
	rx_port_clk_src
};
#endif


// Ethernet Ports
on stdcore[2]: port otp_data = XS1_PORT_32B; // OTP_DATA_PORT
on stdcore[2]: out port otp_addr = XS1_PORT_16C; // OTP_ADDR_PORT
on stdcore[2]: port otp_ctrl = XS1_PORT_16D; // OTP_CTRL_PORT

on stdcore[2]: clock clk_smi = XS1_CLKBLK_5;

on stdcore[2]: mii_interface_t mii =
{
	XS1_CLKBLK_1,
	XS1_CLKBLK_2,

	PORT_ETH_RXCLK,
	PORT_ETH_RXER,
	PORT_ETH_RXD,
	PORT_ETH_RXDV,

	PORT_ETH_TXCLK,
	PORT_ETH_TXEN,
	PORT_ETH_TXD,
};

#ifdef PORT_ETH_RST_N
on stdcore[2]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[2]: smi_interface_t smi = {PORT_ETH_MDIO, PORT_ETH_MDC, 0};
#else
on stdcore[2]: smi_interface_t smi = {PORT_ETH_RST_N_MDIO, PORT_ETH_MDC, 1};
#endif

// IP Config - change this to suit your network.  Leave with all
// 0 values to use DHCP
xtcp_ipconfig_t ipconfig = {
#if 1
		//{ 192,168,137,2 }, // ip address (eg 192,168,0,2)
		//{ 255, 255, 255, 0 }, // netmask (eg 255,255,255,0)
		{ 169, 254, 196, 178 }, // ip address (eg 192,168,0,2)
		{ 255, 255, 0, 0 }, // netmask (eg 255,255,255,0)
		{ 0, 0, 0, 0 } // gateway (eg 192,168,0,1)
		//{ 172,17,0,6 }, // ip address (eg 192,168,0,2)
		//{ 255,255,0,0 }, // netmask (eg 255,255,255,0)
		//{ 172,17,0,1 } // gateway (eg 192,168,0,1)
#else
		{ 0, 0, 0, 0 }, // ip address (eg 192,168,0,2)
		{ 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
		{ 0, 0, 0, 0 } // gateway (eg 192,168,0,1)

#endif
};

/* Begin - to be removed */
void uart_rx_test(streaming chanend cUART)
{
    unsigned uart_char, temp;
    int buf_entries;
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
#if 0
   while (temp != MULTI_UART_GO) cUART :> temp;
   cUART <: 1;
#endif //Temp removed

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
/* End - to be removed */

// Program entry point
int main(void) {
	chan mac_rx[1], mac_tx[1], xtcp[1], connect_status;
	streaming chan cTxUART;
	streaming chan cRxUART;

	par
	{
		// The ethernet server
		on stdcore[2]:
		{
			int mac_address[2];

			ethernet_getmac_otp(otp_data, otp_addr, otp_ctrl,
					(mac_address, char[]));

			phy_init(clk_smi,
#ifdef PORT_ETH_RST_N
					p_mii_resetn,
#else
					null,
#endif
					smi, mii);

			ethernet_server(mii, mac_address,
					mac_rx, 1, mac_tx, 1, smi,
					connect_status);
		}

		// The TCP/IP server thread
		on stdcore[3]:
		{
			uip_server(mac_rx[0], mac_tx[0],
					xtcp, 1, ipconfig,
					connect_status);
		}

		on stdcore[1]: web_server(xtcp[0]);

		// The multi-uart manager thread
		on stdcore[1]: app_manager_handle_uart_data(cTxUART, cRxUART);

		on stdcore[1]: run_multi_uart_tx( cTxUART, uart_tx_ports );

		//on stdcore[1]: uart_rx_test(cRxUART);
		on stdcore[1]: run_multi_uart_rx( cRxUART, uart_rx_ports );

	}
	return 0;
}
