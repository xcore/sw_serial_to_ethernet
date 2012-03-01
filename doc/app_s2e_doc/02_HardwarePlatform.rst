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
   * External oscillator (1.83 MHz) to derive the standard UART baud rates
   * XTAG2 (if program not flashed)
   * Connector jumper wires for loopback demo configuration

Hardware SetUp
++++++++++++++
Multi-Uart component requires 8-bit ports for both transmit and receive ports. 
Following table summarizes TX and RX Multi-UART pin mapping on FRC connector on MC platform

===================== ====================== ====================== =======================
**MUART RX Server**   **MUART TX Server**     ** MUART Channel Id** **Default Telnet port**
===================== ====================== ====================== =======================
FRC Pin #19 [Port 8C] FRC Pin #39 [Port 8A]             0                    46
FRC Pin #20 [Port 8C] FRC Pin #40 [Port 8A]             1                    47
FRC Pin #22 [Port 8C] FRC Pin #42 [Port 8A]             2                    48
FRC Pin #23 [Port 8C] FRC Pin #43 [Port 8A]             3                    49
FRC Pin #24 [Port 8C] FRC Pin #44 [Port 8A]             4                    50
FRC Pin #47 [Port 8C] FRC Pin #46 [Port 8A]             5                    51
FRC Pin #21 [Port 8C] FRC Pin #41 [Port 8A]             6                    52
FRC Pin #NC [Port 8C] FRC Pin #NC [Port 8A]             7                    53
===================== ====================== ====================== =======================

External Clock Usage

=============== =============  =====================
**FRC Pin # **   **Port**      ** Pin Description**
=============== =============  =====================
28              Port 1A        Clock
49              Port 1A        VCC (3.3 v)
50              Port 1A        Ground
=============== =============  =====================

Phase 2
-------
To be updated (Covers slice kit description for subsequent releases)