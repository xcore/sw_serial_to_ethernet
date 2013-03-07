HW platforms
============

Hardware Requirements
---------------------

This application runs on an L1 device on the slicekit core board. Following hardware is required for running this application:
   * Slicekit Core Board XP-SKC-L2 1V0
   * Ethernet Slice XA-SK-E100 1V0
   * OctoUART Slice XA-SK-UART-8 1V0
   * XTAG adapter for Slicekit XA-SK-XTAG2 1V0 (if program not flashed)
   * XTAG2 (if program not flashed)
   * Ethernet cable
   * Power supply 5V

Hardware SetUp
--------------
MultiUART component requires 8-bit ports for both transmit and receive ports. The current version of the Serial to Ethernet application runs on U8 (single tile). The SliceCards should be connected to the SliceKit board in the following manner:

===================== ======================== =======================
**SliceCard**         **SliceKit Connector**   **SliceKit - Jumper**
===================== ======================== =======================
Ethernet              Triangle                 J5
MUART                 Star                     J4
===================== ======================== =======================

.. figure:: images/hardware_setup.jpg
    :align: center
    :width: 50%
    
    Hardware Setup
    
The XA-SK-UART-8 SliceCard has two types of voltage levels of communications.
    * CMOS TTL
    * RS-232
    
By default, XA-SK-UART-8 SliceCard uses the RS-232 levels. In order to use the CMOS TTL levels, short J3 pins (25-26) of the XA-SK-UART-8 Slice Card. At a time, only one voltage level type can be used for all 8 UART channels (RS-232 or CMOS TTL). When using the RS-232 levels, UART device pins must be connected to J4 of the XA-SK-UART-8 SliceCard. When using TTL levels, UART device pins must be connected to J3 of the XA-SK-UART-8 SliceCard (along with J3 25-26 pins shorted). UART mapping information is as below:

================ ===================== =====================
**UART Channel** **J3/J4 Pin no.(TX)** **J3/J4 Pin no.(RX)**
================ ===================== =====================
0                1                     2
1                5                     6
2                7                     8 
3                11                    12
4                13                    14
5                17                    18
6                19                    20
7                23                    24
================ ===================== =====================
