Introduction
============

This documentation covers data interface between the webserver (serial to ethernet - s2e.html) web page and the application. It also provides the steps to add dynamic variables in that web page.

Interface
=========

s2e.html uses Java Script to update and retrieve serial to ethernet configuration settings. The configuration is defined as a skeleton of drop down lists and text inputs using HTML with pre-configured values (for lists). However, each component as an associated 'id' that Java Script uses to get/set data. There are two links provided for 'Get' and 'Set' which executes 'createRequest()' function on an onClick event.

The createRequest() function gets current value of drop down lists and text inputs and encloses each of these data between tild symbols. This forms the HTTP request data. 
Example request: ~<data1>~~<data2>~~<data3>~~<data4>~~<data5>~

It then sends this as a POST request to the server. The server in this case is the xtcp module that is utilized in the serial to ethernet application to work as a webserver. The application must decode this data accordingly. The meaning of each data must be known beforehand. For example, the first data is the 'channel id', the second data is 'parity config' and so on...

In this particular application, the first data represents whether its a 'Get' (0) or a 'Set' (1) configuration. 

Similarly, the application must try and send its reponse in the same format as this web page sends to it - enclosed within '~'. 

Adding Dynamic Variables
========================

It might be required to add some more dynamic variables to web page user interface. To do this, please follow the following steps.

Example: Let's say we want to add a text input 'xxx' which is a part of UART configuration.

Changes required in web page source code
----------------------------------------

In s2e.html:

Step 1: Add skeleton object in HTML

.. figure:: images/dv_1.png
   :align: center

   Add HTML object


Step 2: Add this variable in Update.. functions

.. figure:: images/dv_2.png
   :align: center

   Update Java script functions


Step 3: Add this variable in HTTP request

.. figure:: images/dv_3.png
   :align: center

   Update HTTP Request


Changes required in application source code
-------------------------------------------

**page_access.h**

Update #define WPAGE_NUM_CHAR_IN_CONFIG with maximum number of characters in configuration.

**page_access.c**

Increment #define WPAGE_NUM_HTTP_DYNAMIC_VAR by one (adding just one more dynamic variable; or by the number of dynamic variables plus one - for the Get / Set variable).

**static int wpage_process_cfg(char *response, int *channel_id)**

In this function, you can now update your config (or update the variable from your currrent config).
