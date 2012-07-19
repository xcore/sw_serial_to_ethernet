.. _sec_api:

API
===

S2E Webserver
-------------



S2E Flash access
----------------

Flash access routines are required to access contents in flash when required by the application. The following information is stored in flash:

    * Web pages UI to configure UART channels
    * All UART configuration (parity, baud rate, etc...)
    * IP configuration for the webserver

Each of the above information is stored in a new sector in flash. This makes is easier to read and write information to flash.

Constants
+++++++++

The file src\s2e_flash.h has some constants defined which may be used by other files while accessing flash.

**S2E_FLASH_ERROR**

    Default value = -1
    
    Any errors (like flash not present, wrong flash, unable to write, etc...) while accessing the flash fitted on the board, are represented using this constant.

**S2E_FLASH_OK**

    Default value = 0
    
    All successfull flash operations are represented using this constant.
    
**UART_CONFIG**

    Default value = 0
    
    To be used as a data type parameter while calling flash routines. This also represents the sector index (relative to webpage image) in the flash where UART configuration must be stored.

**IPVER**

    Default value = 1
    
    To be used as a data type parameter while calling flash routines. This also represents the sector index (relative to webpage image) in the flash where IP configuration must be stored.
    
**FLASH_CMD_SAVE**

    Default value = 1
    
    Flash command to 'save' configuration to flash. 

**FLASH_CMD_RESTORE**

    Default value = 2
    
    Flash command to 'restore' configuration from flash.
    
**FLASH_DATA_PRESENT**

    Default value = $
    
    While 'saving' settings to flash, this value is written as the first byte. So, on a 'restore' command, by reading for this sybol, we would know that some data is present in that sector of flash.
    
Main flash thread
+++++++++++++++++

.. doxygenfunction:: s2e_flash

Commands to and results from flash thread
+++++++++++++++++++++++++++++++++++++++++

.. doxygenfunction:: send_cmd_to_flash_thread

.. doxygenfunction:: get_flash_access_result
    
UART configuration related flash functions
++++++++++++++++++++++++++++++++++++++++++

.. doxygenfunction:: send_data_to_flash_thread

.. doxygenfunction:: get_data_from_flash_thread

IP config related flash functions
+++++++++++++++++++++++++++++++++

.. doxygenfunction:: send_ipconfig_to_flash_thread

.. doxygenfunction:: get_ipconfig_from_flash_thread


.. _sec_conf_defines:

Configuration Defines
---------------------

The files multi_uart_tx_conf.h and multi_uart_rx_conf.h must be copied from
app_multi_uart_demo\\src folder to app_serial_to_ethernet_demo\\src folder

The file udp_discovery.h defines ports used for UDP discovery.
This file can set the following defines:

**UDP_RECV_BUF_SIZE**

    Define length of UDP message buffer which holds the incoming UDP test server request
    or corresponding S2E response

**INCOMING_UDP_PORT**

    Define incoming UDP port to listen to device discovery requests from UDP test server

**OUTGOING_UDP_PORT**

    Define outgoing UDP port in order to send device response to UDP test server

**S2E_FIRMWARE_VER**

    Define to specify S2E firmware version. This shall be updated for every release

**UART_RX_FLUSH_DELAY**

    If UART data received is lesser than minimum configured packet size, this defines a 
    minimum wait time to send this data to telnet handler


.. _sec_data_struct:

Data Structures
---------------

.. doxygenstruct:: uart_channel_state_t

.. doxygenstruct:: uart_tx_info

.. doxygenstruct:: uart_rx_info


.. _sec_conf_func:

Configuration Functions
------------------------

.. doxygenfunction:: telnet_to_uart_init

.. doxygenfunction:: udp_discovery_init


.. _sec_xface_func:

Interface functions
-------------------

.. doxygenfunction:: uart_handler

.. doxygenfunction:: udp_discovery_event_handler

.. doxygenfunction:: telnet_to_uart_event_handler
