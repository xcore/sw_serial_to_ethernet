Programming Guide
=================

Getting started
+++++++++++++++

Installation
------------

The following components are required to build the Serial to Ethernet application:
    * sc_multi_uart: git://github.com/xcore/sc_multi_uart.git
    * sc_xtcp: git://github.com/xcore/sc_xtcp.git
    * sc_ethernet: git://github.com/xcore/sc_ethernet.git
    * sc_util: git://github.com/xcore/sc_util.git
    * sc_website: git://github.com/xcore/sc_website.git
    * xcommon: git://github.com/xcore/xcommon.git

All these components are packaged in the software distribution folder. Once these files are extracted, you can install, build and use the software.

Building with the XDE
~~~~~~~~~~~~~~~~~~~~~

To install the software, open the XDE (XMOS Development Tools - latest version as of this writing is 11.11.0) and follow these steps:

#. Choose `File` |submenu| `Import`.

#. Choose `General` |submenu| `Existing Projects into Workspace` and click **Next**.

#. Click **Browse** next to `Select archive file` and select the file firmware ZIP file.

#. Make sure the projects you want to import are ticked in the `Projects` list. Import all the components and whichever applications you are interested in.

#. Click **Finish**.

To build, select `app_serial_to_ethernet` in Project Explorer pane and click the **Build** icon.

Building from the command line
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To build from the command line, change to `app_serial_to_ethernet` directory and execute the command:

       xmake all

Note: Inorder to build the firmware with user required static IP, execute the following command:

       xmake all STATIC_IP=169.254.196.178


Makefiles
~~~~~~~~~

The main Makefile for the project is in the ``app_serial_to_ethernet`` application directory. 
This file specifies build options and used modules. The Makefile uses the common build infrastructure in ``xcommon``.

Installing the application onto flash
-------------------------------------

To upgrade (or flash) the firmware you must, firstly:

#. Connect the XTAG Adapter to the SliceKit and XTAG-2 to the adapter. This XTAG-2 can now be connected to your PC or Mac.

#. Switch on the power supply to the hardware board (Slicekit).

Using Command Line Tools
~~~~~~~~~~~~~~~~~~~~~~~~

Open the XMOS command line tools (Desktop Tools Prompt), change to 'app_serial_to_ethernet' directory and execute the command:

    xmake flash

The serial to ethernet application and associated web pages is now flashed into the XMOS device.

Source Code Structure
+++++++++++++++++++++

Directory Structure
-------------------

The source code is split into application source code and web pages.
The application builds into a single executable using the source code from the modules. 
The modules used by an application are specified using the ``USED_MODULES`` variable in
the application Makefile. For more details on this module structure
please see the documentation in the ``module_xmos_common`` directory.

The source package contains:

.. list-table:: 
 :header-rows: 1

 * - Directory
   - Description
 * - src
   - Source files that implement application functionality
 * - web
   - Web (html) pages used by the web server module
 * - images
   - Images that are displayed on the web (html) pages
   
Supported modules originate from other repositories:

.. list-table:: 
 :header-rows: 1

 * - Directory
   - Description
   - Repository
 * - module_mii_singlethread
   - Lite version of low level ethernet interface over MII
   - sc_ethernet
 * - module_ethernet_smi
   - A library code to communicate with ethernet phy using the SMI protocol
   - sc_ethernet
 * - module_xtcp
   - XTCP TCP/IP stack
   - sc_xtcp
 * - module_multi_uart
   - Multiple UART TX server and RX server
   - sc_multi_uart
 * - module_xc_ptr
   - A library to allow XC code to access pointers via inline assembly calls.
   - sc_util
 * - module_website
   - Embedded website component
   - sc_website
 * - module_mutual_thread_comm
   - A protocol that allows two cores to communicate
   - sc_util
 * - module_xmos_common
   - Common build infrastructure.
   - xcommon
   
Key Files
---------

.. list-table::
 :header-rows: 1

 * - File
   - Description
 * - ``xtcp_client_conf.h``
   - Header file for clients of the TCP/IP stack.
 * - ``udp_discovery.h``
   - Header file for declaring UDP port, firmware version and function declarations required for s2e device discovery
 * - ``uart_config.h``
   - Header file containing delclarations for UART data strcutures and interfacing with multi-uart server component
 * - ``web_server_conf.h``
   - Header file declaring all the functions called from the web pages
 * - ``telnet_config.h``
   - Header file for configuring UARTs via telnet socket
 * - ``multi_uart_rx_conf.h``
   - Header file for multiUART RX server configuration
 * - ``multi_uart_tx_conf.h``
   - Header file for multiUART TX server configuration
 * - ``s2e_conf.h``
   - Header file to enable debug options for s2e application

Notes on Application Interfaces
+++++++++++++++++++++++++++++++

This section provides a brief description on main application interfaces.

UART Configuration
------------------

The initialisation and configuration process for both the RX and TX operations is the same. The files ``multi_uart_tx_conf.h`` and ``multi_uart_rx_conf.h`` are used to configure multiUART TX and RX servers for the default values. For application configuration, the function :c:func:`uart_config_init` is used to apply configuration stored from flash or to use default application defined static configuration. The function :c:func:`uart_set_config` is utilised whenever there is a dynamic configuration change request (ie., a particular UART reconfiguration request). The flow is visualised in :ref:`fig_uart_init_flow`.

.. _fig_uart_init_flow:

.. figure:: images/muart_config_flow.png
    :align: center
    :width: 50%
    
    UART Configuration Flow

Webserver
---------

The webserver handles all HTTP requests from the web clients. A web client may request to change UART settings, save current settings, or apply the previously saved UART seetings etc. Webserver identifies these requests, validates them and services those requests. It calls appropriate UART handler api's to retrieve and set channel settings. For example, for a 'Set' request from the web page, the webserver handler utilizes website component in order to parse the form data from web page, the required UART parameters are extracted and the UART_Handler's uart_set_config api is called to set the new UART configuration.

The Webserver interface utilises sc_website component to implement web server functionality. Refer to the Programming Guide section within the ``SliceKit GPIO Example Applications`` documentation linked from the front page documentation of ``sw_gpio_examples`` repository (git://github.com/xcore/sw_gpio_examples.git). This documentation contains more information on how to utilize the ``Embedded Webserver Function Library`` component in customizing web server applications.

Flash Interface
---------------

The s2e_flash core handles data to/from flash fitted on board. The UART configuration web (html) pages, UART settings and IP configuration are typically stored into flash. Web pages are retrieved upon request from the client to the web server. UART settings can be 'saved' and 'restored' from flash. They are usually done via:
    * Request from web page (HTTP request)
    * From Telnet configuration server
    * Upon startup (to restore restore last saved settings)
    
IP configuration is saved via UDP server request and is requested from flash upon start-up.

