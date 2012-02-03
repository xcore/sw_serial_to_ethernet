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

The tests are provided as part of the component repository in `sc_multi_uart/test/serial_test`.

This python script as a number of command line configuration flags that can be utilised to define the test that you want to carry out. These can be seen by passing the ``-h`` flag to the script. A summary is listed below. 

::

    usage: serial_test.py [-h] [-l] [-t PORTS_FOR_TEST [PORTS_FOR_TEST ...]]
                      [-c CONFIG_STRINGS [CONFIG_STRINGS ...]] [-s SEED]
                      [--echo-test] [--multi-speed-echo-test] [--burst-test]
                      [--multi-speed-burst-test] [--log LOG_FILE]

    XMOS UART Testing System

    optional arguments:
        -h, --help            show this help message and exit
        -l, --list-devices    List available UARTs on this system
        -t PORTS_FOR_TEST [PORTS_FOR_TEST ...]
                        List of UARTs to test (see -l to obtain a full list of
                        available ports)
        -c CONFIG_STRINGS [CONFIG_STRINGS ...]
                        List of configurations in the format baud-bits-parity-
                        stop_bits e.g for 115200 bps with 8 bit characters,
                        even parity and 1 stop bit you would use 115200-8-E-1.
                        Valid parity is N-none, M-mark, S-space, E-even,
                        O-odd. Default configurations will be 115200-8-E-1
        -s SEED, --seed SEED  
                        Integer seed for psuedo random tests - if not given
                        then a random seed will be used and reported
        --echo-test     Do the simple echo test at a single speed
        --multi-speed-echo-test
                        Do the simple echo test at multiple speeds using the
                        auto-reconfiguration command to halve the baud rate
        --burst-test    Do the simple burst test at a single speed
        --multi-speed-burst-test
                        Do the burst test at multiple speeds using the auto-
                        reconfiguration command to halve the baud rate
        --log LOG_FILE  File name for failure logging

To find the names for the UART devices that are connected to the machine you are operating on run the following command.

::
    
        > python serial_test.py -l
        Available Serial ports - 
            /dev/tty.Bluetooth-PDA-Sync
            /dev/tty.Bluetooth-Modem
            /dev/tty.usbserial-FTFLQAFM

The host machine we are using has two serial bluetooth devices and a USB to Serial adapter connected (``/dev/tty.usbserial-FTFLQAFM``). This is the device will use for our testing in this instance.

To run a simple echo test the following command can be used. This will run a test at 115200 bits per second, with 8 bit data, even parity and a single stop bit (as defined by the configuration).

Multiple UART devices can be passed to the `-t` flag. The respective number of configurations needs to be passed to the `-c` flag.

::
    
    > python serial_test.py -t /dev/tty.usbserial-FTFLQAFM -c 115200-8-E-1 --echo-test
    *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
    Simple Echo Tests...

    ------------------------------------------------------
    Running SIMPLE ECHO test on port /dev/tty.usbserial-FTFLQAFM with config 115200-8-E-1
    /dev/tty.usbserial-FTFLQAFM configured
    Using seed 911979
    Waiting for the UART to make sense... sending 'A'
    .Cleaning up UART buffers

    Running test...
    [######100%########]COMPLETED: 2048 of 2048 PASS: 2048 FAIL: 0
    Simple Echo Test COMPLETED => PASS
    ------------------------------------------------------

The burst tests can be run in a similar manner.

Multiple speed tests can be configured to run. This assumes that the echo test application is set to reconfigure to half the baud rate when an `r` is sent to the device. 

When running a burst test the user may desire that any failed burst tests are logged to a file for later analysis. This can be defined using the `--log` flag.

The test script utilises a pseudo-random data stream. Specific pseudo random tests can be re-run by defining the initial seed value using the `-s` flag.
