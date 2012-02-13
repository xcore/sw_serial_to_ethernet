HW platforms
============

Phase 1
-------

Hardware Requirements
+++++++++++++++++++++

This application runs on motor control platform which runs on L2 device. Following hardware is required for running this application:
   * Motor Control board XP-MC-CTRL-L2 1V2
   * Ethernet cable
   * Power supply 5V
   * External oscillator (1.83 MHz) to derive the UART baud rates
   * XTAG2 (if program not flashed)
   * Connector jumper wires for loopback demo configuration

Hardware SetUp
++++++++++++++
Following table summarizes TX and RX Multi-UART pin mapping on MC platform

 +-------------------------------------------------------------------+
 |                        **MUART RX Server on MC**                  |
 +-------------------------------------------------------------------+
 | Port 8C                       | | 8C 0 FRC Pin # 19               |
 |                               | | 8C 1 FRC Pin # 20               |
 |                               | | 8C 2 FRC Pin # 22               |
 |                               | | 8C 3 FRC Pin # 23               |
 |                               | | 8C 4 FRC Pin # 24               |
 |                               | | 8C 5 FRC Pin # 47               |
 |                               | | 8C 6 FRC Pin # 21               |
 |                               | | 8C 7 FRC Pin # NC               |
 +-------------------------------------------------------------------+
 |                       **MUART TX Server on MC **                  |
 | Port 8A                       | | 8A 0 FRC Pin # 39               |
 |                               | | 8A 1 FRC Pin # 40               |
 |                               | | 8A 2 FRC Pin # 42               |
 |                               | | 8A 3 FRC Pin # 43               |
 |                               | | 8A 4 FRC Pin # 44               |
 |                               | | 8A 5 FRC Pin # 46               |
 |                               | | 8A 6 FRC Pin # 41               |
 |                               | | 8A 7 FRC Pin # NC               |
 +-------------------------------+-----------------------------------+
 |                       **Multi Uart Channel Identifier**           |
 +-------------------------------+-----------------------------------+
 |                               0                                   |
 |                               1                                   |
 |                               2                                   |
 |                               3                                   |
 |                               4                                   |
 |                               5                                   |
 |                               6                                   |
 |                               7                                   |
 +-------------------------------+-----------------------------------+
 |                       **Default Telner Port**                     |
 +-------------------------------+-----------------------------------+
 |                               46                                  |
 |                               47                                  |
 |                               48                                  |
 |                               49                                  |
 |                               50                                  |
 |                               51                                  |
 |                               52                                  |
 |                               53                                  |
 +-------------------------------------------------------------------+
 

Phase 2
-------
To be updated (Covers usage of external clock and slice kit description for subsequent releases)