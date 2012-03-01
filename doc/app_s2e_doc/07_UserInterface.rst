User Interface Guide
=====================

This section details on how to use web and telnet user interfaces

Web Interface
--------------

#. Open the browser window

#. Key in the ip address (for e.g. http://169.254.196.178/)
   click **Enter**.

Home page of the application appears

#. Select **Channel Identifier** for the uart channel.

#. Click **Get** to fetch the current (default) configuration for the channel.

In order to change the Uart parameters

#. Select uart parameters to change (Parity, Stop bits, Baud rate, Char Len etc.,)
and telnet port to communicate with uart channel.

#. Click **Set**.


Software is tested for the following web browsers

#. Google Chrome


Telnet interface
----------------

Telnet client is used for uart configuration using a separate socket or for passing client
data to uart channels. These are described as follows

Uart Configuration
++++++++++++++++++
A separate telnet socket (default configured to port 23) is used for configuring uart channels via
telnet client.

#. Open the telnet client (following example uses putty client)

#. Key in the ip address (for e.g. 169.254.196.178)

#. Key in the port number (for uart config, it is 23)

#. Select connection type as telnet
   click **open**.

Telnet connection appears

Use the following format for configuring an uart channel
**#C#P1#P2#P3#P4#P5#P6#P7#@**

where
* # is the parameter separator

* C : Command key word; C for Uart Channel Configuration

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

* P4 : Baud rate configuration
Typical values (bits per second) include
       115200
       57600
       38400
       9600

* P5 : Uart character length
Typical values include
       8
       7
       6
       5
Currently, sw supports only 8

* P6 : Flow control bit (typical values are 0 or 1)
0 : No flow control
1 : Flow control is enabled
Currently sw does not support any flow control

* P7 : Telnet port (typical values are 46 to 53)

#. Click **Enter** to apply the configuration for the channel.

Sample Usage
#C#2#3#1#9600#8#0#48#@

This commands sets uart 2 for the following parameters
Mark parity, two stop bits, baud rate as 9600 bps, uart character length as 8, no flow control 
and telnet port number to communicate with uart channel is 48


Uart Communication
++++++++++++++++++

Telnet_app is an application wrapper to enable and use telnet functionality required for acheiving telnet client communication. 
It utilizes module_telnet_console from xtcp component for the required telnet server functionality.

#. Open the telnet client (following example uses putty client)

#. Key in the ip address (for e.g. 169.254.196.178)

#. Key in the port number (configured values for each uart channel typicaly starts with 46)

#. Select connection type as telnet
   click **open**.

Telnet client connection is now opened; key in the data to be sent to particular uart


Software is tested for the following telnet clients

#. Putty

#. Hercules
