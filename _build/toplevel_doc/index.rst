Serial to Ethernet bridging software
.....................................

:Version: 7a73d542bac78f346ab042100b0ecf8e0ee91a80
:Vendor: XMOS
:Description: Reference design to demonstrate serial device to ethernet bridging applications

:Version: 1.1.2rc0
:Vendor: XMOS

Key Features
============

 * Design fits in a single-tile device
 * Supports up to 8 UARTs at the following baud rates: 115200, 57600, 38400, 
   28800, 19200, 14400, 9600, 7200, 4800, 2400, 1200, 600, 300, 150
 * Web page for UART configuration
 * Telnet server functionality; supports data transfer via telnet socket
   for each UART
 * Telnet mode UART configuration support
 * Device discovery and IP configuration management using UDP

Required tools
==============

xTIMEcomposer studio version 13.0.0 and later

Firmware detail
===============

Overview
--------
The Serial to Ethernet application (referred to as S2E) firmware features Ethernet connectivity with a supporting TCP/IP interface and a UART component supporting multiple UART devices. This application serves as a reference design to demonstrate bridging between Ethernet and serial communication devices. Firmware includes telnet server in order to facilitate data communication from Ethernet host via separate telnet sockets for each of the configured UARTs. Firmware also provides an embedded web server and a dedicated telnet socket for UART configuration management.

Known Issues
============

 * On IE9 web browsers, UART selection from *Index* page may require multiple 
   clicks to render the selected UART configuration page.
 * On Safari web browsers, UART configuration change (SET button) causes 
   S2E device unstable.
 * With 5 or more UARTs enabled for simultaneous full duplex transfer of 
   large files at 115Kbaud, data loss may occur depending on the host 
   configuration. The root cause of this behaviour is under investigation. 
   Setups with 4 or less 115Kbaud UARTs, or any number of UARTs at 
   56KBaud does not exhibit data loss.
 * Data communication on an old unused telnet port (after changing 
   the telnet port to a new one) will render the system unstable; it is 
   recommended to halt UART data communication before changing telnet port.
 * All S2E devices have same MAC addresses. This might result in assigning
   same IP address to different S2Es when DHCP configuration is used.
 * Currently MAC address is same for all boards. This will be 
   fixed by programming unique MAC address to each xCORE on the sliceKIT 
   in subsequent releases. This might result in asssigning same IP addresses
   to multiple S2Es, when used in DHCP configuration mode.
   It is recommended to use the provided UDP test server to set different IP address 
   for such scenarios.
 * DHCP assignment may not work when S2E is connected to local network adapter
   of the host system. Static IP address setting may be used for such configurations.

Required software (dependencies)
================================

  * sc_xtcp
  * sc_multi_uart
  * sc_website
  * sc_ethernet
  * sc_slicekit_support
  * sc_wifi
  * sc_otp
  * sc_util
  * sc_spi

Support
=======

  This package is support by XMOS Ltd. Issues can be raised against the software
  at:

      http://www.xmos.com/support

.. toctree::
   :hidden:

   changelog
