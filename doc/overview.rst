Application Overview 
=====================

Introduction
------------

The Serial to Ethernet application (referred to as S2E) firmware serves as a reference design to add Ethernet connectivity to any serial device. The solution offers flexibility in configuring multiple UART devices (upto 8 UARTs) to bridge them to ethernet networks. Design utilizes some of the existing XMOS SOFTip components for Ethernet, XTCP and MultiUART components.  

The Firmware mainly functions as bridge between serial and ethernet data communication end points. This application includes telnet server in order to facilitate data communication from host applications via separate telnet sockets for each of the configured UARTs. It also provides an embedded web server and a dedicated telnet socket for UART configuration management. UDP mode device discovery feature is provided in order to discover and configure the S2E devices available in the network.

Feature List
------------

Supported
~~~~~~~~~
    * Design fits in a single tile (U8) device
    * 10/100 Mbit Ethernet port
    * Supports up to 8 serial ports at the following baud rates: 115200, 57600, 38400, 
      28800, 19200, 14400, 9600, 7200, 4800, 2400, 1200, 600, 300, 150
    * Device discovery and device IP configuration management using UDP
    * Web page for UART configuration
    * Telnet server functionality; supports data transfer via telnet socket for each UART
    * Flash support for IP and UART configuration, web page storage and retrieval
    * Telnet mode UART configuration support
    * CMOS/TTL level and RS232 level communication for UARTs

Not Supported
~~~~~~~~~~~~~
    * UART to UART communication (serial extender or pair configuration)
    * UDP mode data transfer
    * VirtualCOM port for the UARTs for Configuration