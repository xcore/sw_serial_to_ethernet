=========================
Multi-UART Module Manual
=========================

Introduction
==============

The Multi-UART module aims to provide a software library that allows the use of 8 bit ports for multiple channel UART communication. This library is dynamically reconfigurable for applications that require a level of flexibility during operation.

This document describes the usage of the Multi-UART module and respective API. It follows the examples that are given in the app_multi_uart_demo. This application comprises of a simple transmit and receive test and a more complex echo test application. These can be configured by using the define directives in ``main.xc``.


Programming Guide
=================

Structure
----------

Source Code
++++++++++++

All of the files required for operation are located in the ``module_multi_uart`` directory. The files that are need to be included for use of this module in an application are:

.. list-table::
    :header-rows: 1
    
    * - File
      - Description
    * - ``multi_uart_rxtx.h``
      - Header file for simplified launch of both the TX and RX server threads, also provides the headers for the individual RX and TX API interfaces.
    * - ``multi_uart_common.h``
      - Header file providing configuration ENUM definitions and other constants that may be required for operation
    * - ``multi_uart_rx.h``
      - Header file for accessing the API of the RX UART server - included by ``multi_uart_rxtx.h``
    * - ``multi_uart_tx.h``
      - Header file for accessing the API of the TX UART server - included by ``multi_uart_rxtx.h``

Threads
++++++++

The multi-UART module comprises primarily of two threads that act as transmit (TX) and receive (RX) servers. These are able to be operated independently or launched together via the API. This allows for applications where either RX or TX only are required.

Buffering
++++++++++

Buffering for the TX server is handled within the UART TX thread. The buffer is configurable to the number of buffer slots that are available. Data is transferred to the UART TX thread via shared memory and therefore any client thread must be on the same core as the UART thread.

There is no buffering provided by the RX server. The application must provide a thread that is able to respond to received characters in real time and handle any buffering requirements for the application that is being developed.

Initialisation
----------------

Interfacing to the TX Server
-----------------------------


Interfacing to the RX Server
-----------------------------


