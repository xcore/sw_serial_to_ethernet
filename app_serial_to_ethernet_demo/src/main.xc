// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


/*===========================================================================
Filename: main.xc
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file defines resources (ports, clocks, threads and interfaces)
required to implement serial to ethernet bridge application demostration
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include <platform.h>
#include "uip_server.h"
#include "getmac.h"
#include "ethernet_server.h"
#include "telnetd.h"
#include "app_manager.h"
#include "web_server.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
//#define	DHCP_CONFIG	1	/* Set this to use DHCP */

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/
/* MUART TX port configuration */
#define PORT_TX_TEMP_1 on stdcore[1]: XS1_PORT_8A
#define PORT_TX_TEMP_2 on stdcore[1]: XS1_PORT_1A
#define PORT_TX_TEMP_3 on stdcore[1]: XS1_CLKBLK_1
/* MUART RX port configuration */
#define PORT_RX_TEMP_1 on stdcore[1]: XS1_PORT_8B
#define PORT_RX_TEMP_2 on stdcore[1]: XS1_PORT_1B
#define PORT_RX_TEMP_3 on stdcore[1]: XS1_CLKBLK_2

on stdcore[1]: clock uart_clock_tx = XS1_CLKBLK_1;
on stdcore[1]: clock uart_clock_rx = XS1_CLKBLK_2;

/* Ethernet Ports configuration */
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

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
s_multi_uart_tx_ports uart_tx_ports =
{
	PORT_TX_TEMP_1,
//	PORT_TX_TEMP_2,
//	PORT_TX_TEMP_3
};

s_multi_uart_rx_ports uart_rx_ports =
{
	PORT_RX_TEMP_1,
//	PORT_RX_TEMP_2,
//	PORT_RX_TEMP_3
};

/* IP Config - change this to suit your network.
 * Leave with all 0 values to use DHCP
 */
xtcp_ipconfig_t ipconfig = {
#ifndef DHCP_CONFIG
		{ 169, 254, 196, 178 }, // ip address (eg 192,168,0,2)
		{ 255, 255, 0, 0 }, 	// netmask (eg 255,255,255,0)
		{ 0, 0, 0, 0 } 			// gateway (eg 192,168,0,1)
#else
		{ 0, 0, 0, 0 }, 		// ip address (eg 192,168,0,2)
		{ 0, 0, 0, 0 }, 		// netmask (eg 255,255,255,0)
		{ 0, 0, 0, 0 } 			// gateway (eg 192,168,0,1)

#endif
};

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/


/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  main
*
*  Program entry point function:
*  (i) spwans ethernet, uIp, web server, eth-uart application manager and
*  multi-uart rx and tx threads
*  (ii) interfaces ethernet and uIp server threads, tcp and web server
*  threads, multi-uart application manager and muart tx-rx threads
*
*  \param	None
*
*  \return	0
*
**/
int main(void) {
	chan mac_rx[1];
	chan mac_tx[1];
	chan xtcp[1];
	chan connect_status;
	streaming chan cWbSvr2AppMgr;
	streaming chan cTxUART;
	streaming chan cRxUART;

	par
	{
		// The ethernet server
		on stdcore[2]:
		{
			int mac_address[2];

			ethernet_getmac_otp(
					otp_data,
					otp_addr,
					otp_ctrl,
					(mac_address, char[]));

			phy_init(clk_smi,
#ifdef PORT_ETH_RST_N
					p_mii_resetn,
#else
					null,
#endif
					smi,
					mii);

			ethernet_server(
					mii,
					mac_address,
					mac_rx,
					1,
					mac_tx,
					1,
					smi,
					connect_status);
		}

		/* The TCP/IP server thread */
		on stdcore[3]:
		{
			uip_server(mac_rx[0],
					mac_tx[0],
					xtcp,
					1,
					ipconfig,
					connect_status);
		}

		/* web server thread for handling and servicing http requests
		 * and telnet data communication */
		on stdcore[1]: web_server(xtcp[0], cWbSvr2AppMgr);

		/* The multi-uart application manager thread to handle uart
		 * data communication to web server clients */
		on stdcore[1]: app_manager_handle_uart_data(cWbSvr2AppMgr, cTxUART, cRxUART);

		/* Multi-uart transmit thread */
		on stdcore[1]: run_multi_uart_tx( cTxUART, uart_tx_ports, uart_clock_tx );

		/* Multi-uart receive thread */
		on stdcore[1]: run_multi_uart_rx( cRxUART, uart_rx_ports, uart_clock_rx );

	}
	return 0;
}
