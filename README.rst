Serial to Ethernet bridging software
.....................................

:Latest release: 2.1.0rc1
:Maintainer: xmos
:Description: Demo application to bridge serial devices to Ethernet


:Version: 1.1.2rc0
:Vendor: XMOS

Key Features
============
Demo application to bridge multiple serial devices to an Ethernet network.
 * Supports up to 8 UARTs at the following baud rates: 115200, 57600, 38400, 
   28800, 19200, 14400, 9600, 7200, 4800, 2400, 1200, 600, 300, 150
 * Web page for UART configuration
 * Telnet server functionality; supports data transfer via telnet sockets
   mapped to each of the multiple UARTs
 * Device discovery and IP configuration management using UDP

Required tools
==============

xTIMEcomposer studio version 13.0.0 and later

Documentation
=============

http://xcore.github.io/sw_serial_to_ethernet/

Support
=======

This release of the firmware is supported on the following XMOS devices:
 * XS1-LXA-128 where X >= 8

Required sliceKIT units:
 * xCORE General Purpose (L-series) sliceKIT core board 1V2 (XP-SKC-L2)
 * Ethernet sliceCARD 1V1 (XA-SK-E100)
 * MultiUART sliceCARD (XA-SK-UART-8)

This package is supported by XMOS Ltd. Issues can be raised against the software at:

      http://www.xmos.com/support

Required software (dependencies)
================================

 * sc_xtcp (https://github.com/xcore/sc_xtcp.git)
 * sc_multi_uart (https://github.com/xcore/sc_multi_uart.git)
 * sc_website (https://github.com/xcore/sc_website.git)
 * sc_ethernet (git@github.com:xcore/sc_ethernet.git)
 * sc_slicekit_support (git@github.com:xcore/sc_slicekit_support)
 * sc_otp (git@github.com:xcore/sc_otp)
 * sc_util (git@github.com:xcore/sc_util)
