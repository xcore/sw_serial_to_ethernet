Application Overview 
=====================

Introduction
------------

The Serial to Ethernet application (referred to as S2E) firmware features ethernet connectivity with a supporting TCP/IP interface and a UART component supporting multiple UART devices. Existing XMOS IP components: Ethernet, XTCP and  MultiUART components are used in this application. The Firmware mainly functions as bridge between serial and ethernet data communication end points providing buffers to hold data. Firmware includes telnet server in order to facilitate data communication from ethernet host via separate telnet sockets for each of the configured UARTs, provides an embedded web server and a dedicated telnet socket for UART configuration management and UDP mode device discovery feature in order to determine S2E presence in the network and to respond to UDP discovery server requests.

Feature List
------------

Supported
~~~~~~~~~
    * Design fits in a single-tile (U8) device
    * Supports up to 8 UARTs at the following baud rates: 115200, 57600, 38400, 
      28800, 19200, 14400, 9600, 7200, 4800, 2400, 1200, 600, 300, 150
    * Web page for UART configuration
    * Telnet mode UART configuration support
    * Device discovery and device IP configuration management using UDP
    * Telnet server functionality; supports data transfer via telnet socket for each UART
    * Flash support for IP and UART configuration, web page storage and retrieval

Not Supported
~~~~~~~~~~~~~
    * UART to UART communication (serial extender or pair configuration)
    * UDP mode data transfer
    * VirtualCOM port for the UARTs