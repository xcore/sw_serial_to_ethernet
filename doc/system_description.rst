System Description
==================

This section briefly describes the software components used, thread diagram and resource usage details.

Software Architecture
---------------------

.. figure:: images/s2e_threads.png

Cores
~~~~~

The multi-UART component comprises two logical cores, one acting as a transmit (TX) server for up to 8 uarts, and the other acting as a receive (RX) server for up to 8 uarts.

UART_Handler is an application core that interfaces with the UART RX and TX servers. It handles UART configuration requests, manages the data buffers (FIFO) by storing and transferring the data received from telnet clients to UART TX server, and similarly data received from UART RX server is managed in buffers and notifies TCP_Handler core about data availability.

TCP_Handler is an application core that initializes the application, interfaces with the flash module for UART configuration storage and recovery, and handles all the xtcp application events received from the xtcp module. UDP discovery management, web server handling, telnet data extraction are all implemented in this logical core. 

The XTCP server runs on a single logical core and connects to the Ethernet MAC component. It send events to clients (TCP_Handler) using XC channel. 

The Flash core handles flash data sotrage and retrieval requests from TCP_Handler core based on the application dynamics such as start-up or UI driven request.

Buffering
~~~~~~~~~

Buffering for the TX server is handled by the UART_Handler Core. Data is transferred to the UART TX logical core via a shared memory interface.

There is no buffering provided by the UART RX server. The UART_Handler core is able to respond to received data in real time and store them in a buffer which shares the data to TCP_Handler core via notifcation tokens.

Communication Model
~~~~~~~~~~~~~~~~~~~

The ``sc_multi_uart`` module utilises a combination of shared memory and channel communication. Channel communication is used on both the RX and TX servers to pause the logical core and subsequently release the logical core when required for reconfiguration. The primary means of data transfer for both the RX and TX logical cores is shared memory. The RX logical core utilises a channel to notify any client of available data - this means that events can be utilised within an application to avoid the requirement for polling for received data.

Similarly XTCP server and flash core connects to TCP_handler clients over repective XC channels.


Software components used
------------------------

   * sc_ethernet
   Two thread version of the ethernet component implementing 10/100 Mii ethernet mac and filters

   * sc_xtcp
   Micro TCP/IP stack for use with sc_ethernet component

   * sc_multi_uart
   Component for implementing multiple serial device communication

   * sc_util
   General utility modules for developing for XMOS devices

   * sc_website
   Component framework for Embedded web site development

   * xcommon
   Common application framework for XMOS software

Resource Usage
++++++++++++++

.. figure:: images/ResourceUsage.jpg


[TBD - achievable TCP/IP bandwidth, the performance of the uarts]


UART Configuration
------------------

[TBD -  number of uarts supported, the options for configuring the uarts]

