.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------

The files multi_uart_tx_conf.h and multi_uart_rx_conf.h must be copied from
app_multi_uart_demo\\src folder to app_serial_to_ethernet_demo\\src folder

**UART_RX_CHAN_COUNT**

    Default value = 8

    Define the number of channels that are to be supported, must fit in the port. Also, must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised

**UART_TX_CHAN_COUNT**

    Default value = 8

    Define the number of channels that are to be supported, must fit in the port. Also, must be a power of 2 (i.e. 1,2,4,8) - not all channels have to be utilised

**UART_RX_MAX_BAUD**

    Default value = 115200

    Define maximum baud rate to be supprted for any of the UART channel

**UART_TX_BUF_SIZE**

    Default value = 8

    Define the buffer size in UART word entries - needs to be a power of 2 (i.e. 1,2,4,8,16,32 etc)

The file xtcp_client_conf.h defines configuration fexibility required for XTCP clients in order to use XTCP server functions

**UIP_CONF_RECEIVE_WINDOW**

    Default value = 128
    
    Define window length of TCP packets that the application will receive and process for each TCP packets received from XTCP clients.
    Note this value will be set as default length of application buffers that will be used to hold UART data collected from XTCP clients.

**XTCP_CLIENT_BUF_SIZE**

    Default value = 650
    
    Define MTU size used for XTCP device packet transmissions

The file udp_discovery.h defines ports used for UDP discovery.
This file can set the following defines:

**UDP_RECV_BUF_SIZE**

    Default value = 80
    
    Define length of UDP message buffer which holds the incoming UDP test server request
    or its corresponding S2E response

**INCOMING_UDP_PORT**

    Default value = 15534
    
    Define incoming UDP port to listen to device discovery requests from UDP test server

**OUTGOING_UDP_PORT**

    Default value = 15533
    
    Define outgoing UDP port in order to send device response to UDP test server

**S2E_FIRMWARE_VER**

    Current value = 1.1.2
    
    Define to specify S2E firmware version. This shall be updated for every release

**UART_RX_FLUSH_DELAY**

    Default value = 20000000
    
    If UART data received is lesser than minimum configured packet size, this defines a 
    minimum wait time to send this data to telnet handler
    
The file telnet_config.h defines ports used for Telnet socket used for UART configuration.

**S2E_TELNET_CONFIG_PORT**

    Default value = 23
    
    Define to specify telnet port to use for UART configuration


.. _sec_const:

Constants
---------

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
    
.. _sec_data_struct:

Data Structures
---------------

.. doxygenstruct:: app_state_t

.. doxygenstruct:: uart_config_data_t

.. doxygenstruct:: uart_channel_state_t

.. doxygenstruct:: uart_tx_info

.. doxygenstruct:: uart_rx_info


.. _sec_conf_func:

Configuration Functions
------------------------

.. doxygenfunction:: uart_config_init

.. doxygenfunction:: s2e_webserver_init

.. doxygenfunction:: telnet_to_uart_init

.. doxygenfunction:: udp_discovery_init


.. _sec_xface_func:

Interface functions
-------------------

.. doxygenfunction:: uart_handler

.. doxygenfunction:: tcp_handler

.. doxygenfunction:: telnet_config_event_handler

.. doxygenfunction:: s2e_webserver_event_handler

.. doxygenfunction:: telnet_to_uart_event_handler

.. doxygenfunction:: udp_discovery_event_handler

.. doxygenfunction:: s2e_flash

.. doxygenfunction:: send_data_to_flash_thread

.. doxygenfunction:: get_data_from_flash_thread

.. doxygenfunction:: send_ipconfig_to_flash_thread

.. doxygenfunction:: get_ipconfig_from_flash_thread

.. doxygenfunction:: send_cmd_to_flash_thread

.. doxygenfunction:: get_flash_access_result


.. _sec_module_func:

Module functions
-------------------

.. doxygenfunction:: parse_telnet_buffer

.. doxygenfunction:: parse_config

