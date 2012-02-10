Programming Guide
==================

This section discusses the requirements of the multi-UART module and typical implementation and usage of the API.

Resource Requirements
~~~~~~~~~~~~~~~~~~~~~~~

This section provides an overview of the required resources of the module so that the application designer can operate within these constraints accordingly.

Ports
+++++++

The following ports are required for each of the receive and transmit functions - 

.. list-table::
    :header-rows: 1
    
    * - Operation
      - Port Type
      - Number required
      - Direction
      - Port purpose / Notes
    * - Transmit
      - 8 bit port
      - 1
      - Output
      - Data transmission
    * - Transmit
      - 1 bit port
      - 1
      - Input
      - Optional External clocking (see :ref:`sec_ext_clk`)
    * - Receive
      - 8 bit port
      - 1
      - Input
      - Data Receive

Threads
++++++++++

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
++++++++++

The following is a summary of memory usage of the module for all functionality utilised by the echo test application when compiled at optimisation level 3. It assumes a TX buffer of 16 slots and operating at the maximum of 8 UART channels. This is deemed to be a guide only and memory usage may differ according how much of the API is utilised.

Stack usage is estimated at 460 bytes.

.. list-table::
    :header-rows: 1
    
    * - Operation
      - Code (bytes)
      - Data (bytes)
      - Total Usage (bytes)
    * - Receive Thread
      - 316
      - 424
      - 740
    * - Receive API
      - 410
      - 0
      - 410
    * - Transmit Thread
      - 1322
      - 940
      - 2262
    * - Transmit API
      - 480
      - 0
      - 480
    * - **Total**
      - **2159**
      - **1364**
      - **3523**

**Note** These values are meant as a guide and are correct as of Jan 24. 2012 - they may change if fixes are implemented or functionality is added.
      
Channel Usage
+++++++++++++++

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
++++++++++++++++++++++++++++

The application that interfaces to the receive side of UART component must meet the following timing requirement. This requirement is dependent on configuration so the worst case configuration must be accounted for - this means the shortest UART word (length of the start, data parity and stop bits combined).

.. raw:: latex

    \[ \frac{1}{UART\_CHAN\_COUNT \times \left (  \frac{MAX\_BAUD}{MIN\_BIT\_COUNT} \right )} \]
    
Taking an example where the following values are applied -

    * UART_CHAN_COUNT = 8
    * MAX_BAUD = 115200 bps
    * MIN_BIT_COUNT = 10 (i.e 1 Start Bit, 8 data bits and 1 stop bit)
    
The resultant timing requirement is 10.85 |microsec|. This would be defined and constrained using the XTA tool.

.. |microsec| unicode:: U+03BC U+0053

Structure
~~~~~~~~~~

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

Buffering for the TX server is handled within the UART TX thread. The buffer is configurable allowing the number of buffer slots that are available to be defined. This is only limited by the available memory left by the rest of the code and data memory usage. Data is transferred to the UART TX thread via shared memory and therefore any client thread must be on the same core as the UART thread.

There is no buffering provided by the RX server. The application must provide a thread that is able to respond to received characters in real time and handle any buffering requirements for the application that is being developed.

Communication Model
++++++++++++++++++++

This module utilises a combination of shared memory and channel communication. Channel communication is used on both the RX and TX servers to pause the thread and subsequently release the thread when required for reconfiguration.

The primary means of data transfer for both the RX and TX threads is shared memory. The RX thread utilises a channel to notify any client of available data - this means that events can be utilised within an application to avoid the requirement for polling for received data.

Configuration of the UART Module
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The UART module configuration takes place in two domains - a static compile time configuration (discussed in this section) and a runtime dynamic configuration (as discussed in :ref:`sec_initialisation` and :ref:`sec_reconf_rxtx`. 

Static configuration is done by the application providing configuration header files ``multi_uart_tx_conf.h`` and ``multi_uart_rx_conf.h``. 

.. _sec_tx_conf_header:

Static configuration of UART TX
++++++++++++++++++++++++++++++++

Below is a summary of the configuration options that are in the ``multi_uart_tx_conf.h`` file, their suggested defaults and an explanation of their function.

.. list-table::
    :header-rows: 1
    
    * - Define
      - Default
      - Other options
      - Explanation
    * - UART_TX_USE_EXTERNAL_CLOCK
      - (None)
      - Not defined
      - The presence of this define turns on or off the requirement to use external clocking this is discussed in :ref:`sec_ext_clk`.
    * - UART_TX_CLOCK_RATE_HZ
      - 1843200 | 100000000
      - Any valid clock rate
      - Defines the clock rate that the baud rates are derived from
    * - UART_TX_MAX_BAUD_RATE
      - 115200
      - less than or equal to 115200
      - Define the max baud rate the API will allow configuration. Validated to 115200
    * - UART_TX_CLOCK_DIVIDER
      - (UART_TX_CLOCK_RATE_HZ / UART_TX_MAX_BAUD_RATE)
      - Any appropriate divider
      - It is recommended to leave this at the default. Is used to set the clock divider when configuring clocking from the internal reference clock
    * - UART_TX_OVERSAMPLE
      - 2
      - {1|2}
      - Define the oversampling of the clock - this is where the UART_TX_CLOCK_DIVIDER is > 255 (otherwise set to 1) - only used when using an internal clock reference
    * - UART_TX_BUF_SIZE
      - 16
      - {1,2,4,8,16,32,...}
      - Define the buffer size in UART word entries - needs to be a power of 2 (i.e. 1,2,4,8,16,32)
    * - UART_TX_CHAN_COUNT
      - 8
      - {1,2,4,8}
      - Define the number of channels that are to be supported, must fit in the port. Also, must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised
    * - UART_TX_IFB
      - 0
      - {0..n}
      - Define the number of interframe bits - n should not make the total number of bits in a UART word exceed 32
      
Static configuration of UART RX
++++++++++++++++++++++++++++++++

Below is a summary of the configuration options that are in the ``multi_uart_rx_conf.h`` file, their suggested defaults and an explanation of their function.


.. list-table::
    :header-rows: 1

    * - Define
      - Default
      - Other options
      - Explanation
    * - UART_RX_CHAN_COUNT
      - 8
      - {1,2,4,8}
      - Define the number of channels that are to be supported, must fit in the port. Also, must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised
    * - UART_RX_CLOCK_RATE_HZ
      - 100000000
      - System reference clock rate
      - Defines the clock rate that the baud rates are derived from
    * - UART_RX_MAX_BAUD
      - 115200
      - less than or equal to 115200
      - Define the max baud rate the API will allow configuration. Validated to 115200.
    * - UART_RX_CLOCK_DIVIDER
      - (UART_RX_CLOCK_RATE_HZ / UART_RX_MAX_BAUD)
      - Any appropriate divider
      - It is recommended to leave this at the default. Is used to set the clock divider when configuring clocking using either internal or external clocks.
    * - UART_RX_OVERSAMPLE
      - 4
      - Should remain at 4
      - Oversample count for the max baud rate. It is recommended to leave this value as it is unless it is understood the effects that changing this value will have.
      
.. _sec_initialisation:

Initialisation
~~~~~~~~~~~~~~~~

The initialisation and configuration process for both the RX and TX operations is the same. For configuration the functions :c:func:`uart_rx_initialise_channel` or :c:func:`uart_tx_initialise_channel` is utilised. The flow is visualised in :ref:`fig_uart_init_flow` and a working example taken from the echo test application that is utilised for verification.

.. _fig_uart_init_flow:

.. figure:: images/InitFlow.png

    UART Initialisation Flow

The following working example is taken from `echo_test.c` and shows a typical initial configuration.

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

    
    
.. _sec_interfacing_tx:
    
Interfacing to the TX Server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To transmit data using the TX server the application should make use of :c:func:`uart_tx_put_char`. An example use is shown below. This example, taken from the simple demo application configuration simply takes a string in the form of a character array and pushes it into the buffer one character at a time. When the API indicates that the buffer is full by returning a value of `-1` then the loop moves onto the next channel. 

.. literalinclude:: app_multi_uart_demo/src/main.xc
    :start-after: //:example_tx_buf_fill
    :end-before:  //:

This operation must be completed on the same core as the TX server thread as the communication module utilises shared memory.

.. _sec_interfacing_rx:

Interfacing to the RX Server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To receive data from the RX server the application should make use of the channel that is provided. The channel provides notification to the application of which UART channel has data ready. The data itself is stored in a single storage slot with no buffering. This means that if the application layer fails to meet the timing requirements (as discussed in Client Timing :ref:`sec_client_timing`) data may be lost and/or duplicated.

The echo test example implements an application level buffering for receiving data. This may or may not be required in a particular implementation - dependant on whether timing requirements can be met. The receive and processing loop is shown below.

.. literalinclude:: app_multi_uart_demo/src/echo_test.c
    :start-after: //:rx_echo_example
    :end-before:  //:

Once the token is received over the channel informing the application of the UART channel which has data ready the application uses the :c:func:`uart_rx_grab_char` function to collect the data from the receive slot. This provides an unvalidated word. The application then utilises the :c:func:`uart_rx_validate_char` to ensure that the UART word fits the requirements of the configuration (parity, stop bits etc) and provides the data upon return in the ``uart_char`` variable. This data is then inserted into a buffer.

.. _sec_reconf_rxtx:

Reconfiguration of RX & TX Server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The method for reconfiguring the UART software is the same for both the RX and the TX servers. When the application requires a reconfiguration then a call to :c:func:`uart_tx_reconf_pause` or :c:func:`uart_rx_reconf_pause` needs to be made. When reconfiguring the RX side the server thread will pause immediately, however when pausing the TX side the server thread will pause the application thread to allow the buffers to empty in the TX thread. 

Once the functions exit the server threads will be paused. Configuration is then done utilising the same methodology as initial configuration using a function such as the :c:func:`uart_tx_initialise_channel` or :c:func:`uart_rx_initialise_channel`.

Following the reconfiguration the application must then call :c:func:`uart_tx_reconf_enable` and :c:func:`uart_rx_reconf_enable` to re-enable the TX and RX threads respectively.

The listing below gives an example of reconfiguration that is taken from the echo test demonstration and test application.

.. literalinclude:: app_multi_uart_demo/src/echo_test.c
    :start-after: //:reconf_example
    :end-before:  //:
    
