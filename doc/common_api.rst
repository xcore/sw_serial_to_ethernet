.. _sec_common_api:

Multi-UART Common API Description
===================================

The following describes the shared API between the RX and TX code.

.. _sec_common_enum:

Enum Definitions
-----------------

.. doxygenenum:: ENUM_UART_CONFIG_PARITY

.. doxygenenum:: ENUM_UART_CONFIG_STOP_BITS

.. doxygenenum:: ENUM_UART_CONFIG_POLARITY

.. _sec_common_func:

Combined RX & TX Server Launch Functions
-----------------------------------------

.. doxygenfunction:: run_multi_uart_rxtx_int_clk

.. doxygenfunction:: run_multi_uart_rxtx
