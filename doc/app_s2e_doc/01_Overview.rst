Application Overview 
=====================

Introduction
------------

This application is intended to demonstrate serial to ethernet bridging. Existing XMOS IP for ethernet, XTCP and  Multi UART components are used in this application. Uart configuration is supported using web and telnet client interfaces. Telnet interface is used to transmit and receive data, to and from uarts. Additional logic is provided for uart data buffer management at application level in order to handle buffer overflow and underflow scenarios. This application also serves as an example implementation to use Multi-UART module APIs.
