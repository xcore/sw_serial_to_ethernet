Serial to Ethernet (S2E) briding application Quickstart Guide
=============================================================
This application serves as a reference design to demostrate bridging between ethernet and serial communication devices.
Some of the features of this application include
 * Supports up to 8 serial ports at various standard configuration settings and supports baud rates upto 115200 for each of the UARTs
 * 10/100 Mbit Ethernet port
 * Device discovery and IP configuration management of the S2E devices in the network
 * Webserver to facilitate dynamic UART configuration
 * Telnet server to support data transfer via a telnet socket for each UART
 * Flash memory storage and retrieval for device settings such as IP, UART configuration and web pages
 * CMOS/TTL level and RS232 level communication for UARTs

Host computer setup
-------------------
A computer with:

* Internet browser (Internet Explorer, Chrome, Firefox, etc...)
* An Ethernet port or connected to a network router with spare Ethernet port.
* Download and install the xTIMEcomposer studio (v13.0.0 or later) from XMOS xTIMEcomposer downloads webpage.

Hardware setup
--------------
Required sliceKIT units:

* XP-SKC-L2 sliceKIT L2 core board
* XA-SK-E100 Ethernet sliceCARD
* XA-SK-UART-8 OctoUART sliceCARD
* xTAG-2 and XA-SK-XTAG2 adapter

Setup:

* Connect the ``XA-SK-XTAG2`` adapter to the ``XP-SKC-L2`` core board
* Connect ``XTAG2`` to ``XSYS`` side (``J1``) of the ``XA-SK-XTAG2`` adapter
* Connect the ``XTAG2`` to your computer using a USB cable
* Connect the ``XA-SK-E100`` Ethernet sliceCARD to the ``XP-SKC-L2`` core board's ``TRIANGLE`` (indicated by a white color triangle) slot.
* Using an Ethernet cable, connect the other side of ``XA-SK-E100`` Ethernet sliceCARD to your computer's Ethernet port (or) to a spare Ethernet port of the router.
* Connect the 12V power supply to the core board and switch it ON.

.. figure:: images/hardware_setup.*

   Hardware setup
   
Import and build the application
--------------------------------
Importing the ``serial to ethernet`` reference application:

* Open the xTIMEcomposer studio. 
* Open the *Edit* perspective (Window -> Open Perspective -> XMOS Edit).
* Click *Import* option in the *Project Explorer* window (Import -> General -> Existing Projects into Workspace and click Next).
* Choose *Select archive file* option and click *Browse* button.
* Select s2e release zip file and click *Finish* button
* The application is called as *app_serial_to_ethernet* in the *Project Explorer* window.

Building the ``serial to ethernet`` application:

* Click on the *app_serial_to_ethernet* item in the *Project Explorer* window.
* Click on the *Build* (indicated by a 'Hammer' picture) icon.
* Check the *Console* window to verify that the application has built successfully.

Flash the web pages and device configuration
--------------------------------------------

To flash the web pages and device configuration using xTIMEcomposer studio:

* In the *Project Explorer* window, locate the *app_serial_to_ethernet.xe* and *web_data.bin* in the (app_serial_to_ethernet -> bin).
* Right click on *app_serial_to_ethernet.xe* and click on (Flash As -> Flash Configurations...).
* In the *Flash Configurations* window, double click the *xCORE Application* to create a new flash configuration.
* Navigate to *XFlash Options* tab and apply the following settings:

   * Check *Boot partition size (bytes):* and its value as 0x10000
   * *Other XFlash Options:* as --data bin/web_data.bin
   
* Click on *Apply* and then *Flash* to the XMOS device.
* Check the *Console* window to verify flashing progress.

Run the application
-------------------

To run the application using xTIMEcomposer studio:

* In the *Project Explorer* window, locate the *app_serial_to_ethernet.xe* in the (app_serial_to_ethernet -> Binaries).
* Right click on *app_serial_to_ethernet.xe* and click on (Run As -> xCORE Application).
* In the *Run Configurations* window, double click the *xCORE Application* to create a new xCORE application launch configuration.
* A *Select Device* window appears.
* Select *XMOS XTAG-2 connected to L1* and click *Apply*.
* Click *Run* and check the *Console* window for any messages.

Demo:

* The following message appears in the *Console* window of the xTIMEcomposer studio::

   Address: 0.0.0.0
   Gateway: 0.0.0.0
   Netmask: 0.0.0.0

* At this point, the XMOS device is trying to acquire an IP address in the network. Wait for some time (approximately 10 seconds) for the following message to appear in the *Console* window. Note, the IP address may be different based on your network::

   ipv4ll: 169.254.10.130
   
* Open a web browser (Firefox, etc...) in your host computer and enter the above IP address in the address bar of the browser. It opens a web page as hosted by the webserver running on the XMOS device.

.. figure:: images/webpage.*

   Page hosted by webserver running on XMOS device

@add uart configuration change
@serial-telnet data transfers demo

Next steps
----------

* @flash save/restore options
* @device discovery
* @configure number of UARTs for a different build
* @reference to main documentation pages in the app_s2e folder
