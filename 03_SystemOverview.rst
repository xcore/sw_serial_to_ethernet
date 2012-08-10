System Overview
===============

This section briefly describes the software components used, thread diagram and resource usage details.

Thread diagram of s2e app
-------------------------

.. figure:: images/s2e_BlockDiagram.png
	 
Software components used
------------------------

   * sc_ethernet
   Two thread version of the ethernet component implementing 10/100 Mii ethernet mac and filters

   * sc_xtcp
   Micro TCP/IP stack for use with sc_ethernet component

   * sc_multi_uart
   Component for implementing multiple serial device communication

   * sc_util
   General utility modules for developing for XMOS devices

   * sc_website
   Component framework for Embedded web site development

   * xcommon
   Common application framework for XMOS software

Description of Operation
++++++++++++++++++++++++

To be updated

Resource Usage
++++++++++++++

.. figure:: images/ResourceUsage.jpg
