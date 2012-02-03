Multi-UART Component
......................

:Stable release:  unreleased

:Status:  beta

:Maintainer:  `Paul Hampson <https://github.com/paul-xmos>`_ 

:Description:  Component for creating applications with multiple UART interfaces


Key Features
============

* Support for 8 channels of UART RX & TX on 8 bit ports
* Reconfigurable at runtime
* Supports upto 115200bps in both directions
* Support for a variety of data lengths, parity configurations and stop bit configurations

To Do
=====

* Support for inverted signals

Firmware Overview
=================

There are two apps within this module.

	* app_multi_uart_demo - This is a self contained test application for test and verification of the multi-uart component
	* app_serial_to_ethernet_demo - This is a demonstration application that integrates the multi-uart component with the ethernet and TCP components and provides and ethernet to UART solution over HTTP and Telnet

The primary module is module_multi_uart. This contains the multi-uart module and provides both receive and transmit functionality along with an API for using them.

Known Issues
============

* Implementation will currently fail to receive burst data correctly

Required Repositories
================

* xcommon git\@github.com:xcore/xcommon.git
* sc_xtcp git\@github.com:xcore/sc_xtcp.git
* sc_ethernet git\@github.com:xcore/sc_ethernet.git

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the maintainer for this line.
