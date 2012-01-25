=========================
Multi-UART Module Manual
=========================

Introduction
==============

The Multi-UART module aims to provide a software library that allows the use of 8 bit ports for multiple channel UART communication. This library is dynamically reconfigurable for applications that require a level of flexibility during operation.

This document describes the usage of the Multi-UART module and respective API. It follows the examples that are given in the app_multi_uart_demo. This application comprises of a simple transmit and receive test and a more complex echo test application. These can be configured by using the define directives in ``main.xc``.

Demo Application Configuration
===============================

The demo application can be compiled and run in two different modes.

    * Simple Transmit & Receive Mode

        * This mode of operation produces an application that constantly outputs a string on each UART channel. On the receive side the application will print out via the JTAG interface any characters it receives. This can be looped back by connecting the physical pins together for testing.
        
    * Echo Test Mode
    
        * This mode of operation produces an application that operates as an echo device. This therefore echos back any characters that it receives via the same transmit UART channel.
        
Configuration is done utilising the defines listed out below.

.. literalinclude:: app_multi_uart_demo/src/main.xc
    :start-after: //:demo_app_config
    :end-before:  //:
    
**LOOP_REF_TEST**

    This configures the tests with internal clocking only. This means that no external clock source is required to conduct testing. However it will only operate at multiples the internal reference clock (e.g. 100000 bps).
    
**ECHO_TEST**

    Build the software to run the echo test demo application.
    
**SIMPLE_TEST**

    Build the simple test application
    
**SIMPLE_TEST_DO_RECONF**

    Enable reconfiguration on the simple test application - after a specified time within the application the UART will be reconfigured for a different baud rate.

Programming Guide
==================

Structure
----------

This is an overview of the key header files that are required, as well as the thread structure and information regarding the buffering provision and requirements for the module.

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

Communication Model
++++++++++++++++++++

This module utilises a combination of shared memory and channel communication. Channel communication is used on both the RX and TX servers to pause the thread and subsequently release the thread when required for reconfiguration.

The primary means of data transfer for both the RX and TX threads is shared memory. The RX thread utilises a channel to notify any client of available data - this means that events can be utilised within an application to avoid the requirement for polling for received data.

Initialisation
----------------

The initialisation and configuration process for both the RX and TX operations is the same. For configuration the functions :c:func:`uart_rx_initialise_channel` or :c:func:`uart_tx_initialise_channel` is utilised. The following is example is taken from `echo_test.c` and shows a typical initial configuration.

.. literalinclude:: app_multi_uart_demo/src/echo_test.c
    :start-after: //:config_example
    :end-before:  //:

The next stage of initialisation is to release the server threads from their paused state. Upon start up their default state is to be paused until the following channel communication is completed.

.. literalinclude:: app_multi_uart_demo/src/echo_test.c
    :start-after: //:thread_start_helper_funcs
    :end-before:  //:
    
The above examples use the helper functions that are described in Multi-UART Helper API :ref:`sec_helper_api`. However, if operating within the XC language normal channel interaction can be utilised such as the example below (from the simple test program).

.. literalinclude:: app_multi_uart_demo/src/main.xc
    :start-after: //:xc_release_uart
    :end-before:  //:


    
Interfacing to the TX Server
-----------------------------

To transmit data using the TX server the application should make use of :c:func:`uart_tx_put_char`. An example use is show below. This example, taken from the simple demo application configuration simply takes a string in the form of a character array and pushes it into the buffer one character at a time. When the API indicates that the buffer is full by returning a value of `-1` then the loop moves onto the next channel. 

.. literalinclude:: app_multi_uart_demo/src/main.xc
    :start-after: //:example_tx_buf_fill
    :end-before:  //:

This operation must be completed on the same core as the TX server thread as the communication modeul utilises shared memory.

Interfacing to the RX Server
-----------------------------

To receive data from the RX server the application should make use of the channel that is provided. The channel provides notification to the application of which UART channel had data ready. The data itself is store in a single storage slot with no buffering. This means that if the application layer fails to meet the timing requirements (as discussed in Client Timing :ref:`sec_client_timing`) data may be lost and/or duplicated.

The echo test example implements an application level buffering for receiving data. This may or may not be required in a particular implementation - dependant on whether timing requirements can be met. The receive and processing loop is shown below.

.. literalinclude:: app_multi_uart_demo/src/echo_test.c
    :start-after: //:rx_echo_example
    :end-before:  //:

Once the token is received over the channel informing the application of the UART channel which has data ready the application uses the :c:func:`uart_rx_grab_char` function to collect the data from the receive slot. This provides an unvalidated word. The application then utilises the :c:func:`uart_rx_validate_char` to ensure that the UART word fits the requirements of the configuration (parity, stop bits etc) and provides the data upon return in the ``uart_char`` variable. This data is then inserted into a buffer.

Reconfiguration of RX & TX Server
----------------------------------

TO BE COMPLETED

Resource Requirements
======================

This section provides an overview of the required resources of the module so that the application designer can operate within these contraints accordingly.

Threads
--------

.. list-table::
    :header-rows: 1
    
    * - Operation
      - Thread Count
      - Notes
    * - Receive
      - 1
      - Single thread server, may require application defined buffering thread - requires 62.5MIPS per thread
    * - Transmit
      - 1
      - Single thread server - requires 62.5MIPS per thread

Memory
-------

.. list-table::
    :header-rows: 1
    
    * - Operation
      - Code
      - Data
      - Stack
    * - Receive
      - TBD
      - TBD
      - TBD
    * - Transmit
      - TBD
      - TBD
      - TBD
      
Channel Usage
--------------

.. list-table::
    :header-rows: 1
    
    * - Operation
      - Channel Usage & Type
    * - Receive
      - 1 x Streaming Chanend
    * - Transmit
      - 1 x Streaming Chanend

.. _sec_client_timing:

Client Timing Requirements
---------------------------

If the application requires custom buffering on the receive side then the buffering thread must take no more time than the following equation allows.

.. raw:: latex

    \[ \frac{1}{\left (  \frac{MAX\_BAUD}{MIN\_BIT\_COUNT} \right )} \]
    
Taking an example where the following values are applied -

    * MAX_BAUD = 115200 bps
    * MIN_BIT_COUNT = 10 (i.e 1 Start Bit, 8 data bits and 1 stop bit)
    
The resultant timing requirement is 86.8 |microsec|. This would be defined and constrained using the XTA tool.

.. |microsec| unicode:: U+03BC U+0053


