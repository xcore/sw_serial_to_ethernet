HW platforms
============

Phase 1
-------

Hardware Requirements
+++++++++++++++++++++

This application runs on motor control platform, on an on L2 device. Following hardware is required for running this application:
   * Motor Control board XP-MC-CTRL-L2 1V2
   * Ethernet cable
   * Power supply 5V
   * External oscillator (1.83 MHz) to derive the UART baud rates
   * XTAG2 (if program not flashed)
   * Connector jumper wires for loopback demo configuration

Hardware SetUp
++++++++++++++
Following table summarizes TX and RX Multi-UART pin mapping on MC platform

 +-----------------------------------------------------------------------------------------------------+
 | **MUART RX Server** **MUART TX Server**   **Multi Uart Channel Identifier** **Default Telner Port** |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 19 |  Port 8A - Pin # 39 |            0                    |         46             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 20 |	 Port 8A - Pin # 40 |            1                    |         47             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 22 |	 Port 8A - Pin # 42 |            2                    |         48             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 23 |	 Port 8A - Pin # 43 |            3                    |         49             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 24 |	 Port 8A - Pin # 44 |            4                    |         50             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 47 |	 Port 8A - Pin # 46 |            5                    |         51             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # 21 |	 Port 8A - Pin # 41 |            6                    |         52             |
 +-----------------------------------------------------------------------------------------------------+
 | Port 8C - Pin # NC |	 Port 8A - Pin # NC |            7                    |         53             |
 +-----------------------------------------------------------------------------------------------------+ 

Phase 2
-------
To be updated (Covers usage of external clock and slice kit description for subsequent releases)