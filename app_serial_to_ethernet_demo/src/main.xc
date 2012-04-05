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
#include <xs1.h>
#include "getmac.h"
#include "uip_single_server.h" //Enable this for 2T Eth comp
//#include "uip_server.h" //Enable this for 5T Eth comp
//#include "ethernet_server.h" //Enable this for 5T Eth comp
#include "app_manager.h"
#include "web_server.h"
#include "multi_uart_rxtx.h"
#include <flash.h>
#include "s2e_flash.h"

/*---------------------------------------------------------------------------
 constants
 ---------------------------------------------------------------------------*/
//#define	DHCP_CONFIG	1	/* Set this to use DHCP */
#define		TWO_THREAD_ETH		1 //Enable this to use 2 thread ethernet component
#define 	XSCOPE_EN 0     /* set this to 1 for xscope printing */

#if XSCOPE_EN == 1
#include <xscope.h>
#endif

/*---------------------------------------------------------------------------
 ports and clocks
 ---------------------------------------------------------------------------*/
on stdcore[0] : fl_SPIPorts flash_ports =
{ PORT_SPI_MISO,
  PORT_SPI_SS,
  PORT_SPI_CLK,
  PORT_SPI_MOSI,
  XS1_CLKBLK_3
};

/* MUART TX port configuration */
#define PORT_TX on stdcore[1]: XS1_PORT_8A
#define PORT_RX on stdcore[1]: XS1_PORT_8C
//#define PORT_TX_TEMP_3 on stdcore[1]: XS1_CLKBLK_1
/* MUART RX port configuration */
//#define PORT_RX_TEMP_1 on stdcore[1]: XS1_PORT_8B
//#define PORT_RX_TEMP_2 on stdcore[1]: XS1_PORT_1B
//#define PORT_RX_TEMP_3 on stdcore[1]: XS1_CLKBLK_2

on stdcore[1]: clock uart_clock_tx = XS1_CLKBLK_1;
/* Define 1 bit external clock */
on stdcore[1]: in port uart_ref_ext_clk = XS1_PORT_1A;

on stdcore[1]: clock uart_clock_rx = XS1_CLKBLK_2;

#ifndef TWO_THREAD_ETH

/* Ethernet Ports configuration */
on stdcore[0]: port otp_data = XS1_PORT_32B; // OTP_DATA_PORT
on stdcore[0]: out port otp_addr = XS1_PORT_16C; // OTP_ADDR_PORT
on stdcore[0]: port otp_ctrl = XS1_PORT_16D; // OTP_CTRL_PORT
on stdcore[0]: out port reset = PORT_SHARED_RS;

on stdcore[0]: clock clk_smi = XS1_CLKBLK_5;

on stdcore[0]: mii_interface_t mii =
{ XS1_CLKBLK_1,
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
    on stdcore[0]: out port p_mii_resetn = PORT_ETH_RST_N;
    on stdcore[0]: smi_interface_t smi = {PORT_ETH_MDIO, PORT_ETH_MDC, 0};
#else
    //on stdcore[0]: smi_interface_t smi = {PORT_ETH_RST_N_MDIO, PORT_ETH_MDC, 1};
    on stdcore[0]: smi_interface_t smi = {PORT_ETH_MDIO, PORT_ETH_MDC, 0};
#endif
#else //TWO_THREAD_ETH
#define PORT_ETH_FAKE    on stdcore[0]: XS1_PORT_8A

on stdcore[0]: struct otp_ports otp_ports = { XS1_PORT_32B, XS1_PORT_16C, XS1_PORT_16D };

on stdcore[0]: mii_interface_t mii =
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

    PORT_ETH_FAKE,
  };

on stdcore[0]: port p_reset = PORT_SHARED_RS;
on stdcore[0]: smi_interface_t smi = { 0, PORT_ETH_MDIO, PORT_ETH_MDC };
on stdcore[0]: clock clk_smi = XS1_CLKBLK_5;

#endif //TWO_THREAD_ETH

/*---------------------------------------------------------------------------
 typedefs
 ---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
 global variables
 ---------------------------------------------------------------------------*/
s_multi_uart_tx_ports uart_tx_ports =
{
    PORT_TX
};

s_multi_uart_rx_ports uart_rx_ports =
{
	PORT_RX
};

/* IP Config - change this to suit your network.
 * Leave with all 0 values to use DHCP
 */
xtcp_ipconfig_t ipconfig =
{
#ifndef DHCP_CONFIG
       { 192, 168, 0, 2 }, // ip address (eg 192,168,0,2)
       { 255, 255, 255, 0 },     // netmask (eg 255,255,255,0)
       { 0, 0, 0, 0 }          // gateway (eg 192,168,0,1)
#else
       { 0, 0, 0, 0 }, // ip address (eg 192,168,0,2)
       { 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
       { 0, 0, 0, 0 }  // gateway (eg 192,168,0,1)
#endif
};

/*---------------------------------------------------------------------------
 static variables
 ---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
 implementation
 ---------------------------------------------------------------------------*/

#ifndef TWO_THREAD_ETH
/** =========================================================================
 *  init_ethernet_server
 *
 *  Function to initialise and run the Ethernet server
 *
 **/
void init_ethernet_server(port p_otp_data,
                          out port p_otp_addr,
                          port p_otp_ctrl,
                          clock clk_smi,
                          smi_interface_t &p_smi,
                          mii_interface_t &p_mii,
                          chanend c_mac_rx[],
                          chanend c_mac_tx[],
                          chanend c_connect_status,
                          out port p_reset)
{
    int mac_address[2];

    // Bring the ethernet PHY out of reset
    p_reset <: 0x2;

    // Get the MAC address
    ethernet_getmac_otp(p_otp_data, p_otp_addr, p_otp_ctrl, (mac_address, char[]));

    // Initiate the PHY
    phy_init(clk_smi, null, p_smi, p_mii);

    // Run the Ethernet server
    ethernet_server(p_mii, mac_address, c_mac_rx, 1, c_mac_tx, 1, p_smi, c_connect_status);
}
#endif

void dummy()
{
    while (1);
}



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
// Program entry point
int main(void)
{
#ifndef TWO_THREAD_ETH
	chan mac_rx[1];
    chan mac_tx[1];
    chan connect_status;
#endif //TWO_THREAD_ETH
    chan xtcp[1];
    chan cPersData;
	streaming chan cWbSvr2AppMgr;
	streaming chan cAppMgr2WbSvr;
	streaming chan cTxUART;
	streaming chan cRxUART;

	par
	{
#ifndef TWO_THREAD_ETH
	            /* The ethernet server */
	            on stdcore[0]: init_ethernet_server(otp_data,
	                otp_addr,
	                otp_ctrl,
	                clk_smi,
	                smi,
	                mii,
	                mac_rx,
	                mac_tx,
	                connect_status,
	                reset);
	            
	            /* The TCP/IP server thread */
	            on stdcore[0]: uip_server(mac_rx[0],
	                mac_tx[0],
	                xtcp,
	                1,
	                ipconfig,
	                connect_status);
#else //TWO_THREAD_ETH
        on stdcore[0]:
        {
            char mac_address[6];

            ethernet_getmac_otp(otp_ports, mac_address);

            // Bring PHY out of reset
            p_reset <: 0x2;

            // Start server
            uipSingleServer(clk_smi, null, smi, mii, xtcp, 1, ipconfig, mac_address);
        }
#endif //TWO_THREAD_ETH

#if XSCOPE_EN == 1
	            on stdcore[0]: {
	                xscope_register (0 , 0 , " " , 0, " " );
	                xscope_config_io ( XSCOPE_IO_BASIC );
	                dummy();
	            }
#endif

	            on stdcore[0]: flash_data_access(cPersData);
	            /*
	            on stdcore[0]: dummy();
	            on stdcore[0]: dummy();
	            on stdcore[0]: dummy();
	            on stdcore[0]: dummy();
	            on stdcore[0]: dummy();
	            */
	            
	            /* web server thread for handling and servicing http requests
	            * and telnet data communication */
	            on stdcore[1]: web_server(xtcp[0], cWbSvr2AppMgr, cAppMgr2WbSvr, cPersData);
	            
	            /* The multi-uart application manager thread to handle uart
	            * data communication to web server clients */
	            on stdcore[1]: app_manager_handle_uart_data(cWbSvr2AppMgr, cAppMgr2WbSvr, cTxUART, cRxUART);
#if 0
	            /* Multi-uart transmit thread */
	            on stdcore[1]: run_multi_uart_tx( cTxUART, uart_tx_ports, uart_clock_tx );
	            
	            /* Multi-uart receive thread */
	            on stdcore[1]: run_multi_uart_rx( cRxUART, uart_rx_ports, uart_clock_rx );
#else
	            /* run the multi-uart RX & TX with a common external clock - (2 threads) */
	            on stdcore[1]: run_multi_uart_rxtx( cTxUART,  uart_tx_ports, cRxUART, uart_rx_ports, uart_clock_rx, uart_ref_ext_clk, uart_clock_tx);
#endif
#if 0
	            on stdcore[1]: dummy();
	            on stdcore[1]: dummy();
	            on stdcore[1]: dummy();
	            on stdcore[1]: dummy();
#endif
	 } // par

	return 0;
}
