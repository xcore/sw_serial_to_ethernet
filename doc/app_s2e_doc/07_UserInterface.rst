User Interface Guide
=====================

This section details on how to use web and telnet user interfaces

Web Interface
--------------

#. Open the browser window

#. Key in the ip address (for e.g. http://169.254.196.178/) and press **Enter**.

Home page of the application appears

#. Click on a **Uart Channel** to configure.

A new page for the selected channel appears with its settings. In order to change the Uart parameters

#. Select uart parameters to change (Parity, Stop bits, Baud rate, Char Len or Telnet port)

#. Click **Set**.

#. If configuration is set successfully, the **Response** text will say 'Ok'

#. Click on **Back to main config page** to select a different Uart channel or save the current settings to flash.

#. When clicked on **Save** in the main config page, current set configuration will be saved to flash. On successfull save, the **Response** text will say 'Ok'

Software is tested for the following web browsers

#. Google Chrome

#. Mozilla Firefox


Telnet interface
----------------

Telnet client can also be used for uart configuration or passing client data to uart channels (and vice versa). These are described as follows:

Uart Configuration
++++++++++++++++++
A separate telnet socket (default configured to port 23) is used for configuring uart channels via telnet client.

#. Open the telnet client (following example uses Hercules 3.2.5)

#. Switch to **TCP Client** tab

#. Key in the ip address (for e.g. 169.254.196.178)

#. Key in the port number (for uart config, it is 23)

#. Click **Connect**

Uart configuration server's welcome message appears in the data pane of Telnet client

Use the following format for configuring an uart channel
~C~~P1~~P2~~P3~~P4~~P5~~P6~@

where
* ~ is the parameter separator

* @ is command termination marker

* C : Command code
        1 : Get channel configuration for a particular channel
        2 : Set channel configuration
        3 : Save current configuration of all channels to flash
        4 : Restore and set channel configuration from flash

* P1 : Uart Channel Identifier (typical values range for 0 to 7)

* P2 : Parity Configuration (typical values range for 0 to 4)
        0 : No Parity
        1 : Odd Parity
        2 : Even Parity
        3 : Mark (always 1) parity bit
        4 : Space (always 0) parity bit

* P3 : Stop bits configuration (typical values are 0 or 1)
        0 : Single stop bit
        1 : Two stop bits

* P4 : Baud rate configuration. Typical values (bits per second) include
        115200
        57600
        38400
        28800
        19200
        14400
        9600
        7200
        4800
        2400
        1200
        600
        300
        150

* P5 : Uart character length. Typical values include
        5
        6
        7
        8
        9

* P7 : Telnet port (typical values are 10 to 65536)

#. Click **Enter** to apply the configuration for the channel.

Sample Usage:
+++++++++++++

* Get: ~1~~0~@
        Gets channel '0' configuration.
        
* Set: ~2~~0~~2~~0~~115200~~8~~100~@
        Sets channel '0' with: Even parity, single stop bits, 115200 baud, 8 character length and telnet port to communicate with this channel as 100.
        
* Save: ~3~@
        Save current set configuration of all channels to flash
        
* Restore: ~4~@
        Restores and sets channels configuration from flash

Uart Data Communication
+++++++++++++++++++++++

#. Open the telnet client (following example uses Hercules 3.2.5)

#. Switch to **TCP Client** tab

#. Key in the ip address (for e.g. 169.254.196.178)

#. Key in the port number (default configured values for each uart channel starts with 46)

#. Click **Connect**

Telnet client connection is now opened; key in the data to be sent to particular uart

Software is tested for the following telnet clients

#. Putty

#. Hercules
