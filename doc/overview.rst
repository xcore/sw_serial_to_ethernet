Application Overview 
=====================

Introduction
------------

The Serial to Ethernet application (referred to as S2E) firmware serves as a reference design to add Ethernet connectivity to any serial device. The solution offers flexibility in configuring multiple UART devices (up to 8 UARTs) to bridge them to Ethernet networks. Design utilizes some of the existing XMOS xSOFTip components to implement Layer 2 Ethernet MAC, Ethernet/TCP and multiUART functionality.

The firmware mainly functions as bridge between serial and Ethernet data communication end points. This application includes a telnet server in order to facilitate data communication from host applications via separate telnet sockets for each of the configured UARTs. It also provides an embedded web server and a dedicated telnet socket for UART configuration management. UDP mode device discovery feature is provided in order to discover and configure the S2E devices available in the network.

Feature list
------------

Supported
~~~~~~~~~
    * 10/100 Mbit Ethernet port
    * Supports up to 8 serial ports at the following baud rates: 115200, 57600, 38400, 
      28800, 19200, 14400, 9600, 7200, 4800, 2400, 1200, 600, 300, 150
    * Supports various parity mode, character length, start/stop bit
    * Device discovery and device IP configuration management using UDP
    * Web page for UART configuration
    * Telnet server functionality: supports data transfer via telnet socket for each UART
    * Flash support for IP and UART configuration, web page storage and retrieval
    * Telnet mode UART configuration support
    * CMOS/TTL level and RS232 level communication for UARTs
    * All the 8 UARTs can be configured in different configurations

Not supported
~~~~~~~~~~~~~
    * UART to UART communication (serial extender or pair configuration)
    * UDP mode data transfer
    * VirtualCOM port for the UARTs for Configuration

