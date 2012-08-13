Serial To Ethernet Bridging Software
.....................................

:Version: 1.1.2rc0
:Vendor: XMOS
:Description: Reference design to bridge serial (UART) devices to ethernet

Key Features
============

 * Design fits in a single-core device
 * Supports up to 8 UARTs at the following baud rates: 115200, 57600, 38400, 
   28800, 19200, 14400, 9600, 7200, 4800, 2400, 1200, 600, 300, 150
 * Web page for UART configuration
 * Telnet server functionality; supports data transfer via telnet socket
   for each UART
 * Telnet mode UART configuration support
 * Device discovery and IP configuration management using UDP

Required Tools
==============

11.11.0 and above


Support
=======

SUPPORTED FEATURES: XMOS Devices

This release of the firmware is supported on the following XMOS devices:
 * XS1-L01A-TQ48-C5
 * XS1-L01A-TQ48-I5
 * XS1-L01A-LQ64-C5
 * XS1-L01A-LQ64-I5
 * XS1-L01A-TQ128-C5
 * XS1-L01A-TQ128-I5

SUPPORTED FEATURES: Reference Hardware

 * XMOS SliceKit Reference Board
 * XMOS Ethernet Slice 
 * XMOS Multi-UART Slice


Firmware Detail
===============

Overview
--------
The Serial to Ethernet application (referred to as S2E) firmware features 
ethernet connectivity with a supporting TCP/IP interface and a UART 
component supporting multiple UART devices. The Firmware mainly 
functions as an application bridge between serial and ethernet data 
communication end points providing buffers to hold data. Firmware includes
telnet server in order to facilitate data communication from 
ethernet host via separate telnet sockets for each of the configured UARTs.
Firmware also provides an embedded web server and a dedicated telnet socket 
for UART configuration management.

Documentation
=============

https://github.com/xcore/sc_multi_uart/tree/master/doc/app_s2e_doc


Known Issues
============

 * On IE9 web browser, UART selection from Index page may require multiple 
   clicks to render the selected UART configuration page
 * On Safari web browser, UART configuration change (SET button) causes 
   S2E device unstable
 * With 5 or more uarts enabled for simultaneous full duplex transfer of 
   large files at 115Kbaud, data loss may occur depending on the host 
   configuration. The root cause of this behaviour is under investigation. 
   Setups with 4 or less 115Kbaud uarts, or any number of uarts at 
   56KBaud never exhibit data loss   
 * Data communication on an old unused telnet port (after changing 
   the telnet port to new one) will render the system unstable; it is 
   recommended to halt UART data communication before changing telnet port
 * All S2E devices have same MAC address. This might result in assigning
   same IP address to different S2Es when DHCP is used. 
 * Currently MAC address is fixed and same for all boards. This will be 
   fixed by programming unique MAC address to each xcore on the slicekit 
   in subsequent release. This might result in asssigning same IP addresses
   to multiple S2Es, when used in DHCP configuration mode.
   It is recommended to use UDP test server to set different IP address for 
   such a case.
 * DHCP assignment may not work when S2E is connected to local network adapter
   of the host system. Static IP address setting may be used for such a case
   

Support
=======

  This package is supported by XMOS Ltd. Issues can be raised against the software
  at:

      http://www.xmos.com/support

