Hardware platforms
==================

Hardware requirements
---------------------

This application runs on an L1 device on the sliceKIT core board. Following hardware is required for running this application:
   * xCORE General Purpose (L-series) sliceKIT core board 1V2 (XP-SKC-L2)
   * Ethernet sliceCARD 1V1 (XA-SK-E100)
   * Multi UART sliceCARD (XA-SK-UART-8)
   * xTAG-2 debug adapter and sliceKIT connector (xTAG-2 and XA-SK-XTAG2)
   * Ethernet cable
   * Power supply 5V

Hardware setup
--------------
MultiUART component requires 8-bit ports for both transmit and receive ports. The current version of the *Serial to Ethernet* application runs on a single tile device. The sliceCARDs should be connected to the sliceKIT core board in the following manner:

===================== ======================== =======================
**sliceCARD**         **sliceKIT Connector**   **sliceKIT - Jumper**
===================== ======================== =======================
Ethernet              Triangle                 J5
MultiUART             Star                     J4
===================== ======================== =======================

.. figure:: images/hardware_setup.jpg
    :align: center
    :width: 50%
    
    Hardware setup
    
The Multi UART sliceCARD has two types of voltage levels of communications.
    * CMOS TTL
    * RS-232
    
By default, Multi UART sliceCARD uses the RS-232 levels. In order to use the CMOS TTL levels, short J3 pins (25-26) of the Multi UART sliceCARD. Only one voltage level type can be used for all 8 UART channels (RS-232 or CMOS TTL). When using the RS-232 levels, UART device pins must be connected to J4 of the Multi UART sliceCARD. When using TTL levels, UART device pins must be connected to J3 of the Multi UART sliceCARD (along with J3 25-26 pins shorted). UART mapping information is as below:

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
