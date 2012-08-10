Multi-UART Component
......................

:Version: 1.0.0rc0
:Vendor: XMOS
:Description: Multiple UART to Ethernet (TELNET) bridge, plus web server controller

Key Features
============

* Support for 8 channels of UART RX & TX on 8 bit ports
* Reconfigurable at runtime
* Supports upto 115200bps in both directions
* Support for a variety of data lengths, parity configurations and stop bit configurations, start bit polarity

To Do
======

Firmware Overview
=================

There are two apps within this module.

	* app_multi_uart_demo - This is a self contained test application for test and verification of the multi-uart component
	* app_serial_to_ethernet_demo - This is a demonstration application that integrates the multi-uart component with the ethernet and TCP components and provides and ethernet to UART solution over HTTP and Telnet

The primary module is module_multi_uart. This contains the multi-uart module and provides both receive and transmit functionality along with an API for using them.

Known Issues
============

* None

Required software (dependencies)
================================

  * sc_xtcp
  * xcommon (if using develpoment tools earlier than 11.11.0)
  * sc_ethernet

Support
=======

  This package is support by XMOS Ltd. Issues can be raised against the software
  at:

      http://www.xmos.com/support

