System Overview
===============

This section briefly describes the design of the application.

Block diagram and Thread diagram of s2e app
-------------------------------------------

.. figure:: images/s2e_BlockDiagram.png

   * Ethernet MII interface supports Ethernet device communication. This component utilizes five threads for interfacing clients to PHY
   * XTCP component for TCP/IP stack
   * Webserver to support HTTP and Telnet client interfaces
   * Ethernet-Uart application manager thread 
      * Interfaces with Uart TX and RX server threads in order to configure, and manage Uart specific channel data
      * Interfaces with web server thread to handle the TCP/IP client events
	 
Description of Operation
++++++++++++++++++++++++

Uart Configuration and Data Managemnt

.. figure:: images/FlowDiagram.png
