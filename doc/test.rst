.. _sec_test:

Module Testing Scripts
=======================

The module is provided with a python testing script that utilises the echo test application to verify the operation of the Multi-UART module. It covers two particular traffic types.

    * Simple slow speed character traffic

        * This type of traffic is not disimilar to manually typed in characters. They will have a pause in the order of milliseconds between each character.
        
    * Burst data traffic
        
        * This form of traffic is more akin to communication between two devices that don't require human input, but streams strings of symbols across the UART interface. This traffic typically has minimal space between the symbols as it will be well buffered.
        
Test Script Use
----------------

The test scripts require a Python environment with PySerial installed (see http://pyserial.sourceforge.net/), as well as a suitable serial device to connect to your hardware.

**TO BE COMPLETED**
