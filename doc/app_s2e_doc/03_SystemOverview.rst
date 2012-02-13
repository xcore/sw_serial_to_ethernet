System Overview
===============

This section briefly describes the design of the application.

Block diagram and Thread diagram of s2e app:

   * Eth - TCP/IP - Web Server - EM - MUART Tx and Rx
      * Check s2e design doc and update this

   * Ethernet MII interface supports Ethernet device communication (utilizes 5T eth interface for this implementation)
   * Webserver supports HTTP and Telnet
   * Ethernet-Uart manager thread interfaces with Uart TX and RX server threads in order to configure, and manage Uart specific channel data
   * Utilizes MUART api set to achieve the server communication
      * <<Embed code snippet for a sample case here>>
   * Additionally, this thread interfaces with web server thread to handle the TCP/IP events
	 
description of operation
include the flow / cross functional diagrams here
design of the application pinout.
