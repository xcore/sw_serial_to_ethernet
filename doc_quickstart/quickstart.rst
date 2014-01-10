Serial to Ethernet (S2E) bridging application quickstart guide
=============================================================
This application serves as a reference design to demonstrate bridging between Ethernet and serial communication devices.
Some features of this application are:

* 10/100 Mbit Ethernet port
* Supports up to 8 serial ports with baud rates up to 115200 at standard configuration settings
* Webserver to facilitate dynamic UART configuration
* Telnet server to support data transfer via a telnet socket associated with each UART
* Device discovery and IP configuration management of the S2E devices in the network
* Flash memory storage and retrieval for device settings such as IP, UART configuration and web pages
* CMOS/TTL level and RS232 level communication for UARTs

Host computer setup
-------------------
A computer with:

* Internet browser (Internet Explorer, Chrome, Firefox, etc...)
* With spare Ethernet port.
* Download and install the xTIMEcomposer studio (v13.0.0 or later) from XMOS xTIMEcomposer downloads webpage.

For serial-telnet data communication demo, the following are required in addition to the above:

* A null serial cable to DB-9 connector. The cable will need a cross over between the UART RX and TX pins at each end.
* If the computer does not have a DB-9 connector slot, any USB-UART cable can be used. For the demo, we use the BF-810 USB to UART adapter (``http://www.bafo.com/products/accessories/usb-devices/bf-810-usb-to-serial-adapter-db9.html``).
* A suitable terminal client software. For MAC users, try SecureCRT (``http://www.vandyke.com/download/securecrt/``) and cutecom (``http://cutecom.sourceforge.net/``) for Linux users. We use hercules client (``http://www.hw-group.com/products/hercules/index_en.html``) on a Windows platform for the demo.

Hardware setup
--------------
Required sliceKIT units:

* XP-SKC-L2 sliceKIT L2 core board
* XA-SK-E100 Ethernet sliceCARD
* XA-SK-UART-8 OctoUART sliceCARD
* xTAG-2 and XA-SK-XTAG2 adapter

Setup:

* Connect the ``XA-SK-XTAG2`` adapter to the ``XP-SKC-L2`` sliceKIT core board
* Connect ``XTAG2`` to ``XSYS`` side (``J1``) of the ``XA-SK-XTAG2`` adapter
* Connect the ``XTAG2`` to your computer using a USB cable
* Connect the ``XA-SK-UART-8`` OctoUART sliceCARD to the ``XP-SKC-L2`` core board's ``STAR`` (indicated by a white colour star) slot.
* Connect the ``XA-SK-E100`` Ethernet sliceCARD to the ``XP-SKC-L2`` core board's ``TRIANGLE`` (indicated by a white colour triangle) slot.
* Using an Ethernet cable, connect the other side of ``XA-SK-E100`` Ethernet sliceCARD to your computer's Ethernet port.
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

* At this point, the XMOS device is trying to acquire an IP address in the network. Wait for some time (approximately 20 seconds) for the following message to appear in the *Console* window. Note, the IP address may be different based on your network::

   ipv4ll: 169.254.161.178
   
* Open a web browser (Firefox, etc...) in your host computer and enter the above IP address in the address bar of the browser. It opens a web page as hosted by the webserver running on the XMOS device.

.. figure:: images/webpage.*

   Page hosted by webserver to support UART configuration

* To change the configuration of a UART via web page, click on any UART, say UART1. It opens a new page for configuring the selected UART1.
* Observe the *Telnet Port* value for the selected UART. This is the telnet port number on which the UART1 is bridged.
* Alter the *Baud Rate* settings from *115200* to *57600* by choosing this value from the drop box.
* Click on *Set* button and verify the *Response:* value is populated as *Ok*.
* Click *Back to main config page* link to go back to the home page and verify the modified UART settings are intact by clicking on the same UART1.
* On the main page, click on *Save* button to store any modified UART settings onto the flash.

.. figure:: images/modify_uart_configuration.*

   Modifying UART configuration via web page

Serial-Telnet data communication demo:

In addition to the above hardware set-up

* Connect a null serial cable to DB-9 connector on ``XA-SK-UART-8`` sliceCARD.
* Connect other end of cable to DB-9 connector slot on the host or USB-UART adapter.
* Identify the serial (COM) port number provided by the Host or the USB to UART adapter and open a suitable terminal software for the selected serial port (refer to the Hercules or SecureCRT documentation above).

* Configure the host terminal console program as follows: 115200 baud, 8 bit character length, even parity, 1 stop bit, no hardware flow control. The Transmit End-of-Line character should be set to `CR` (other options presented will probably be `LF` and `CR\LF`).
* Open the serial device on the host console program
* Configure the telnet client application with ip address as XMOS device address. Key in the port number as *46* in order to connect to the UART0.
* Click *Connect* to the telnet server running on the device. A welcome message appears on the client console.

.. figure:: images/terminal_config.*

   Screenshot of Hercules application for serial console and telnet client

* Key in some data from serial console and observe the data is displayed on the telnet console.
* Now send some data from the telnet console and verify the same data on the serial console.
* Explore the terminal client options to transfer a file in both directions and observe the duplex data transfer in action.
 
.. figure:: images/data_communication.*

   Data communication between telnet and serial console

Next steps
----------

* Connect two or more USB-UART adapters to the host and ``XA-SK-UART-8`` sliceCARD. Configure the terminal clients for the correct configuration as detailed in the above *Serial-Telnet data communication demo*. Test the data communication between the connected UARTs and their corresponding Telnet sockets.

* Detach the ``xTAG-2`` and ``XA-SK-XTAG2`` adapter from the ``XP-SKC-L2`` sliceKIT core board. Connect ``XA-SK-E100`` Ethernet sliceCARD to a spare Ethernet port of the router. Navigate to udp_test_server folder available in the release package. If your platform is a MAC or a linux host, execute the udp_server.py script. If you are using a Windows host, navigate to (udp_test_server -> windows -> udp_server.exe), right-click on udp-server.exe and run as Administrator. The script displays the selected network adapter on the console. If there are multiple network adapters on your host, ensure the ip address used by the script corresponds to the one used by your network adapter connected to the router. Now, select option ``1`` to discover the S2E devices available on the network. Look at the S2E device ip address as displayed by the script. Select other choices to change ip configration settings of the S2E device(s).

* Take a look at the ``http://xcore.github.io/sw_serial_to_ethernet`` for a more detailed documentation on using various features, design and programming guide for the application.
