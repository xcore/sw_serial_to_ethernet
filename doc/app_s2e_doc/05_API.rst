.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------

The files multi_uart_tx_conf.h and multi_uart_rx_conf.h must be copied from
app_multi_uart_demo\\src folder to the application rsc folder

The file app_manager.h delcares data structures and interfaces required for
application manager thread to communicate with http and telnet clients,
and multi-uart tx and rx threads. 
This file can set the following defines:

**TX_CHANNEL_FIFO_LEN**

    This define sets the length of the application buffer to hold the 
    overflow data from Multi-UART TX server.

**RX_CHANNEL_FIFO_LEN**

    This define sets the length of the application buffer to hold the 
    data received from Multi-UART RX server thread.

**HTTP_PORT**

    Port number for http client connection. Typically set to 80

.. _sec_data_struct:

Data Structures
---------------

.. doxygenstruct:: STRUCT_UART_CHANNEL_CONFIG

.. doxygenstruct:: s_uart_tx_channel_fifo

.. doxygenstruct:: s_uart_rx_channel_fifo

.. doxygenstruct:: app_mgr_event_type_t

.. doxygenstruct:: s_telnet_conn_info

.. _sec_conf_func:

Configuration Functions
------------------------

.. doxygenfunction:: uart_channel_init

.. doxygenfunction:: httpd_init

.. doxygenfunction:: telnetd_init_conn

.. doxygenfunction:: apply_default_uart_cfg_and_wait_for_muart_tx_rx_threads

.. doxygenfunction:: listen_on_default_telnet_ports

.. _sec_xface_func:

Interface functions
-------------------

.. doxygenfunction:: app_manager_handle_uart_data

.. doxygenfunction:: web_server

.. doxygenfunction:: httpd_recv

.. doxygenfunction:: httpd_send

.. doxygenfunction:: fill_uart_channel_data

.. doxygenfunction:: wpage_process_request

.. _sec_app_buf_mgt_func:

Application buffer management functions
---------------------------------------

.. doxygenfunction:: update_uart_rx_channel_state

.. doxygenfunction:: fill_uart_channel_data_from_queue

.. doxygenfunction:: get_uart_channel_data

.. doxygenfunction:: telnetd_send_client_data
