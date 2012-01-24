.. _sec_rx_api:

Multi-UART Receive API Description
===================================

The following describes the public API for use in applications and the API's usage.

.. _sec_rx_conf_defines:

Configuration Defines
----------------------

The file ``multi_uart_rx_conf.h`` must be provided in the application source code. This file should comprise of the following defines:

**UART_RX_CHAN_COUNT**

    Define the number of channels that are to be supported, must fit in the port. Also, must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised
    
**UART_RX_CLOCK_RATE_HZ**

    This defines the master clock rate - in this implementation this is the system clock in Hertz. This should be 100000000.
    
**UART_RX_MAX_BAUD**

    Define the maximum application baud rate - this implementation is validated to 115200 baud
    
**UART_RX_CLOCK_DIVIDER**

    This should be defined as ``(UART_RX_CLOCK_RATE_HZ/UART_RX_MAX_BAUD)``. But some use cases may require a custom divide.
    
**UART_RX_OVERSAMPLE**

    Define receive oversample for maximum baud rate. This should be left at 4.

.. _sec_rx_data_struct:

Data Structures
----------------

.. doxygenstruct:: STRUCT_MULTI_UART_RX_PORTS

.. doxygenstruct:: STRUCT_MULTI_UART_RX_CHANNEL

.. _sec_rx_conf_func:

Configuration Functions
------------------------

.. doxygenfunction:: uart_rx_initialise_channel

.. doxygenfunction:: uart_rx_reconf_pause

.. doxygenfunction:: uart_rx_reconf_enable

.. _sec_rx_data_validation_func:

Data Validation Functions
--------------------------

.. doxygenfunction:: uart_rx_validate_char

Data Fetch Functions
---------------------

.. doxygenfunction:: uart_rx_grab_char

.. _sec_rx_server_func:

Multi-UART RX Server
---------------------

.. doxygenfunction:: run_multi_uart_rx
