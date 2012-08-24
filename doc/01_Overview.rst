Application Overview 
=====================

Introduction
------------

The Serial to Ethernet application (referred to as S2E) firmware features ethernet connectivity with a supporting TCP/IP interface and a UART component supporting multiple UART devices. Existing XMOS IP components: Ethernet, XTCP and  MultiUART components are used in this application. The Firmware mainly functions as bridge between serial and ethernet data communication end points providing buffers to hold data. Firmware includes telnet server in order to facilitate data communication from ethernet host via separate telnet sockets for each of the configured UARTs, provides an embedded web server and a dedicated telnet socket for UART configuration management and UDP mode device discovery feature in order to determine S2E presence in the network and to respond to UDP discovery server requests.