Programming Guide
=================

This section provides information on application interfaces.

Thread Diagram
--------------

.. figure:: images/threads.png

Flash Interface
---------------

The s2e_flash thread handles data to/from flash fitted on board. The UART configuration web pages (html), UART settings and IP configuration are stored in flash. Web pages are retrieved upon request from the client to the web server. UART settings can be 'saved' and 'restored' from flash. They are usually done via:
    * Request from web page (HTTP request)
    * From Telnet configuration server
    * Upon startup (to restore restore last saved settings)
    
IP configuration is saved via UDP server request and is requested from flash upon start-up.

Webserver
+++++++++

The webserver handles all HTTP requests. The web client may request to change UART settings, save current settings, etc... Webserver identifies these requests, validates them and services those requests. It calls appropriate UART handler api's to retrieve and set channel settings. For example, a 'Set' request from web page is validated (the form data from web page containing UART parameters) and the requested channel's configuration is appropriately changed with the new one.



