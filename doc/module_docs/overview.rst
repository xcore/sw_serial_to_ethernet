Introduction
==============

The Multi-UART module provides a software library that allows the use of 8 bit ports for multiple channel UART communication. This library is dynamically re-configurable for applications that require a level of flexibility during operation.

This document describes the usage of the Multi-UART module and respective API. It follows the examples that are given in the app_multi_uart_demo. This application comprises of a simple transmit and receive test and a more complex echo test application. These can be configured by using the define directives in ``main.xc``.

Supported Functionality
------------------------

The Multi-UART provides the following functionality. All options are dynamically reconfigurable via the API.

.. list-table::
    :header-rows: 1
    
    * - Function
      - Operational Range
      - Notes
    * - Baud Rate
      - 150 to 115200 bps
      - Dependent on clocking (see :ref:`sec_ext_clk`)
    * - Parity
      - {None, Mark, Space, Odd, Even}
      - 
    * - Stop Bits
      - {1,2}
      -
    * - Data Length
      - 1 to 30 bits
      - Max 30 bits assumes 1 stop bit and no parity.

.. _sec_ext_clk:

Clocking
---------

The module can be configured to either use an external clock source or an internal clock source. External clock source only applies to the TX portion of the module (see :ref:`sec_tx_conf_header`). The advantage of using an external clock source is that an exact baud rate can be achieved by dividing down a master clock such as 1.8432MHz. This is a typical method that standard RS232 devices will use.

Using internal clocking is possible, but for TX the implementation currently limits the application to configuring baud rates that divide exactly into the internal clock. So if the system reference runs at 100MHz the maximum baud rate is 100kbaud.

The RX implementation uses the internal clock under all circumstances. Clock drift is handled by the implementation utilising oversampling to ensure that the bit is sampled as close to the centre of the bit time as possible. This minimises error due to the small drift that is encountered. The syncronisation of the sampling is also reset on every start bit so drift is minimised in a stream of data.

It should be noted that if extremely long data lengths are used the drift encountered may become large as the fractional error will accumulate over the length of the UART word. By taking the fractional error (say for an internal clock of 100MHz and a baud rate of 115200bps we have a fractional error of 0.055) and multiplying it by the number of bits in a UART word (for 8 data bits, 1 parity and one stop bit we have a word length of 11 bits). Thus for the described configuration a drift of 0.61 clock ticks is encountered. This equates to 0.07%.
