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

