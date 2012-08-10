.. _sec_tx_api:

Multi-UART Transmit API 
========================

The following describes the public API for use in applications and the API's usage.

.. _sec_tx_conf_defines:

Configuration Defines
----------------------

The file ``multi_uart_tx_conf.h`` must be provided in the application source code. This file should comprise of the following defines:

**UART_TX_USE_EXTERNAL_CLOCK**

    Define whether to use an external clock reference for transmit - do not define this if using the internal clocking

**UART_TX_CHAN_COUNT**

    Define the number of channels that are to be supported, must fit in the port. Also, must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised
    
**UART_TX_CLOCK_RATE_HZ**

    This defines the master clock rate - if using an external clock then set this appropriately (e.g. 1843200 for a 1.8432MHz external clock)
    
**UART_TX_MAX_BAUD**

    Define the maximum application baud rate - this implementation is validated to 115200 baud
    
**UART_TX_CLOCK_DIVIDER**

    This should be defined as ``(UART_TX_CLOCK_RATE_HZ/UART_TX_MAX_BAUD_RATE)``. But some use cases may require a custom divide.
    
**UART_TX_OVERSAMPLE**

    Define the oversampling of the clock - this is where the UART_TX_CLOCK_DIVIDER is > 255 (otherwise set to 1) - only used when using an internal clock reference
    
**UART_TX_BUF_SIZE**

    Define the buffer size in UART word entries - needs to be a power of 2 (i.e. 1,2,4,8,16,32)
    
**UART_TX_IFB**

    Define the number of interframe bits

.. _sec_tx_data_struct:

Data Structures
----------------

.. doxygenstruct:: STRUCT_MULTI_UART_TX_PORTS

.. doxygenstruct:: STRUCT_MULTI_UART_TX_CHANNEL

.. _sec_tx_conf_func:

Configuration Functions
------------------------

.. doxygenfunction:: uart_tx_initialise_channel

.. doxygenfunction:: uart_tx_reconf_pause

.. doxygenfunction:: uart_tx_reconf_enable

.. _sec_tx_func:

Transmission Functions
--------------------------

.. doxygenfunction:: uart_tx_assemble_word

.. doxygenfunction:: uart_tx_put_char

.. _sec_tx_server_func:

Multi-UART TX Server
---------------------

.. doxygenfunction:: run_multi_uart_tx

