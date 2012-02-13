Programming Guide
=================

This section provides information on application interfaces.

Web Server
----------

Telnet interface
++++++++++++++++

Http interface
++++++++++++++


Application Manager
-------------------

Web page parser module
----------------------

Web server handles data communication to and from user client interfaces from
TCP/IP interface. Web server acts as an interface to http and telnet modules by 
establishing and managing sessions, processing various application configuration 
and data processing requests by coordinating with application manager.

Telnet_app is an application wrapper to enable and use telnet module functionality
required for the bridging application.

Http module parses http requests from web clients, identify the request type and 
service those requests. As an example, telnet and Uart configuration changes are 
received from Http clients and are conveyed to the application manager data strcutures.

Application manager handles uart data traffic from Multi-UART Tx and Rx servers.
Additionally, application data from various user clients are managed in the user 
configurable Tx and Rx application buffers in order to handle buffer overflow
and underflow scenarios.
<<Include the implementation snippets for timer/event functionality>>
Following list summarized the functionality of application manager:

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

Web page parser module parses the content from web clients, extracts the dynamic data, 
idenitfy the type of client request (Get/Set), and service accordingly. For page
get requests, dynamic data is fecthed from application configuration data structure,
maps them to page variables; similarly, for set requests, data from page variables 
are applied to members of the application configuration data structure.


