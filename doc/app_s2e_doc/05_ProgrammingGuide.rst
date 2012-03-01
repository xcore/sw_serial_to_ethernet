Programming Guide
=================

This section provides information on application interfaces.

Application Manager
-------------------

Application Manager handles data communication to and from user clients via TCP/IP interface. Application Manager interfaces to http and telnet modules by establishing and managing sessions; processes various uart configuration requests and data processing requests by coordinating with uart data manager. Additionally, this interface polls (timer based) each application RX buffer in a round robin fashion, for any uart data and sends to appropriate user clients.

Telnet interface
++++++++++++++++

Telnet_app is an application wrapper to enable and use telnet functionality required for acheiving telnet client communication. It utilizes module_telnet_console from xtcp component for the required telnet server functionality.
A separate telnet socket is used for uart configuration. Similarly for uart data communication, telnet ports configured for respective uart channels are used.

Http interface
++++++++++++++

Http module parses http requests from web clients, identify the request type and service those requests. As an example, telnet and Uart configuration changes are received from web clients and are conveyed to the application manager data strcutures.

Web page parser
+++++++++++++++

Web page parser module parses the content from web clients, extracts the dynamic data, identify the type of client request (Read/Update), and service accordingly. For page get requests, dynamic data is fecthed from application configuration data structure, maps them to page variables; similarly for set requests, data from page variables are applied to relevant application configuration data structure.

Uart Data Manager
-------------------

Uart data manager handles uart data traffic to and from Multi-UART Tx and Rx servers. Application data from various user clients are managed in the user configurable Tx and Rx application buffers in order to handle buffer overflow and underflow scenarios. A default call back  implementation is provided to process the telnet client data and send it to Multi UART TX server.

To handle UART TX buffer overflow scenario, data is stored in application buffer in case server buffer is full; a timer based polling mechanism ensures to post this data from appliation buffer to TX server buffer; upon this timer event, UART channels are scanned in a
round robin fashion.
The same thread utilizes a RX channel to receive UART RX data whenever any UART channel data is available and stores the data in application RX buffers.

Application thread must ensure that RX server channel data is not missed while processing other functionality in the uart manager thread; hence care must be taken care to keep the thread functions light weight and return to thread loop in order to wait and process
the channel data; hence Rx data should take a more priority over processing periodic TX data. In order not to miss any UART RX data, the process time required for each loop of uart manager thread must not exceed the time period of a UART character receive. This
should also be ensured by xta checks at compile time.

.. literalinclude:: ../../app_serial_to_ethernet_demo/src/app_manager.xc
   :start-after: // #pragma xta endpoint "ep_1"
   :end-before: // break ;


Following summarizes the functionality of application manager:

Uart and telnet client configuration management

        Applies default uart cofniguration at the start up

        Enables uart reconfiguration

        Enables telnet reconfiguration

.. literalinclude:: ../../app_serial_to_ethernet_demo/src/app_manager.xc
   :start-after: // case cWbSvr2AppMgr :> WbSvr2AppMgr_chnl_data :
   :end-before: // break ;

Data structure management

        Initializing the application buffers

        State management of application buffers interfacing Multi-UART server and user clients

        Timer and event based polling of application buffers to send or receive data from Tx and Rx servers

.. literalinclude:: ../../app_serial_to_ethernet_demo/src/web_server.xc
   :start-after: // Loop forever processing TCP events
   :end-before: // }

