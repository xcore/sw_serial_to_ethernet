Programming Guide
=================

This section provides information on application interfaces.

Web Server
----------

Web server handles data communication to and from user client interfaces from
TCP/IP interface. Web server acts as an interface to http and telnet modules by 
establishing and managing sessions, processing various application configuration 
and data processing requests by coordinating with application manager. Additionally,
web server polls (timer based) for any data from uart channels to be sent to 
telnet clients, by scanning each application RX buffers in a round robin fashion and
sends it to appropriate telnet client.

Telnet interface
++++++++++++++++

Telnet_app is an application wrapper to enable and use telnet module functionality
required for the bridging application. It utilizes module_telnet_console methods. 
to achieve the telnet server functionality.

Http interface
++++++++++++++

Http module parses http requests from web clients, identify the request type and 
service those requests. As an example, telnet and Uart configuration changes are 
received from Http clients and are conveyed to the application manager data strcutures.

Web page parser
+++++++++++++++

Web page parser module parses the content from web clients, extracts the dynamic data, 
idenitfy the type of client request (Get/Set), and service accordingly. For page
get requests, dynamic data is fecthed from application configuration data structure,
maps them to page variables; similarly, for set requests, data from page variables 
are applied to members of the application configuration data structure.

Application Manager
-------------------

Application manager handles uart data traffic to and from Multi-UART Tx and Rx servers.
Additionally, application data from various user clients are managed in the user 
configurable Tx and Rx application buffers in order to handle buffer overflow
and underflow scenarios.A default call back function implementation is provided to receive 
the telnet client data and send it to Multi UART TX server.

To handle UART TX buffer overflow scenario, data is stored in application buffer in case 
server buffer is full, and a timer based polling mechanism ensure to post this data from 
appliation buffer to TX server buffer; upon a timer event, UART channels are scanned in a
round robin fashion
The same thread utilizes a RX channel to receive UART RX data whenever there is any UART
channel data is available and stores the data in application RX buffers;

Application thread must ensure that RX server channel data is not missed while processing
other functionality in the application manager thread; hence care must be taken care to 
keep the thread functions light weight and return to main loop in order to wait and process
the channel data; hence Rx data should take a more priority over processing periodic TX data.
In order not to miss any UART RX data, the process time required for each loop of an 
application manager thread must not exceed the time period of a UART character receive. This
should also be ensured by xta checks at compile time.

<<Include the implementation snippets for timer/event functionality>>

Following summarizes the functionality of application manager:

Uart and telnet configuration management
	Applies default uart cofniguration at the start up
	Enables uart reconfiguration
	Enables telnet reconfiguration
	<<Embed sample code snippet here>>

Data structure management
	Initializing the application buffers
	State management of application buffers interfacing Multi-UART server and user clients
	Timer and event based polling of application buffers to send or receive data from Tx and Rx servers
	<<Include the timer diagram and implementation snippets>>
	<<Embed sample code snippet here>>

Thread communication summary
++++++++++++++++++++++++++++

From Thread  To Thread  Communication  Event types
TCP/IP       Web Server Chan-tcp_svr   Handle TCP events from TCP Stack
				       

