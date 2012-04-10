import argparse
import sys
import progressBar
import random
from telnet_tests import XmosTelnetTestSuite
from serial_tests import XmosSerialTestSuite
from xmos_test import XmosTestException
import serial.tools.list_ports as list_ports
from itertools import izip
from serial import SerialException
from s2e_system_tests import XmosSerialToEthernetSystemTests
import platform

def list_com_ports():
    port_list = list_ports.comports()    
    if port_list is not None and len(port_list) is not 0:
        print "Available Serial ports - "
        for port in list_ports.comports():
            print "\t"+port[0]
    else:
        print "No serial ports found by pySerial - you might be using cygwin where you can use /dev/ttySXX where XX = (nn-1) with nn being the COM port number (so COM11 is /dev/ttyS10)"

def pairwise(iterable):
    "s -> (s0,s1), (s2,s3), (s4, s5), ..."
    a = iter(iterable)
    return izip(a, a)
        
def process_args():
    parser = argparse.ArgumentParser(description='XMOS Serial to Ethernet Testing System')
    
    parser.add_argument('-l', '--list-serial-devices', action='store_const', const=True, default=False, help='List available UARTs on this system', dest='list_devices')
    parser.add_argument('-v', action='store_const', const=True, default=False, help='Be verbose', dest='verbose')
    parser.add_argument('-p', action='store_const', const=True, default=False, help='Show progress bars', dest='prog_bar')
    parser.add_argument('--serial-targets', nargs='+', help='List of UARTs to test (see -l to obtain a full list of available ports)', dest='ports_for_test')
    parser.add_argument('--serial-conf', nargs='+', metavar='/dev/serial_dev', help='List of configurations in the format baud-bits-parity-stop_bits e.g for 115200 bps with 8 bit characters, even parity and 1 stop bit you would use 115200-8-E-1. Valid parity is N-none, M-mark, S-space, E-even, O-odd. Default configurations will be 115200-8-E-1', dest='config_strings')
    parser.add_argument('--telnet-targets', metavar='address:port', nargs='+', help='List of telnet targets in the format address:port', dest='telnet_targets')
    parser.add_argument('--telnet-conf-targets', metavar='address:port', nargs='+', help='List of telnet configuration targets in the format address:port', dest='telnet_conf_targets')
    parser.add_argument('--seed', help='Integer seed for psuedo random tests - if not given then a random seed will be used and reported', dest='seed', type=int)
    parser.add_argument('--log', nargs=1, help='File name for failure logging', dest='log_file')
    parser.add_argument('--set-test-duration', nargs=2, help='Set the test duration - applies to all tests that can be run over a period of time.', dest='test_duration', metavar=('<duration>','{cycles|seconds|minutes|hours|days}'))
    parser.add_argument('--serial-echo-test', action='store_const', const=True, default=False, help='Do the simple serial echo test at a single speed, uses --serial-targets')
    parser.add_argument('--serial-multi-speed-echo-test', const=True, default=False, action='store_const', help='Do the simple echo test at multiple speeds using the auto-reconfiguration command to halve the baud rate, users --serial-targets')
    parser.add_argument('--serial-burst-echo-test', const=True, default=False, action='store_const', help='Do the simple burst test at a single speed')
    parser.add_argument('--serial-multi-speed-burst-echo-test', const=True, default=False, action='store_const', help='Do the burst test at multiple speeds using the auto-reconfiguration command to halve the baud rate')
    parser.add_argument('--app-start-up-check-using-telnet', const=True, default=False, action='store_const', help='Run app_start_up_check_using_telnet test')
    parser.add_argument('--app-maximum-connections-telnet', const=True, default=False, action='store_const', help='Run app_maximum_connections_telnet test')
    parser.add_argument('--application-telnet-port-uart-data-check-echo-loop-back', const=True, default=False, action='store_const', help='Run application_telnet_port_uart_data_check_echo_loop_back test. Test duration can be changed with --set-test-duration')
    parser.add_argument('--application-telnet-port-uart-data-check-cross-loop-back', nargs='+', dest='application_telnet_port_uart_data_check_cross_loop_back', help='Run application_telnet_port_uart_data_check_cross_loop_back test with master (TX) and slave (RX) telnet targets of the form <address>:<port>, multiple pairs will run the tests on those targets. Test duration can be changed with --set-test-duration', metavar=('<address>:<port>') )
    parser.add_argument('--application-telnet-read-write-command-check', const=True, default=False, action='store_const', help='Run application_telnet_read_write_command_check test')
    parser.add_argument('--data-filler', nargs=4, help='Send random data via telnet & UART and verify data coming out of telnet.', metavar=('<addr_tx:port_tx>','</dev/tx_serial>', '<addr_rx:port_rx>','</dev/rx_serial>'), dest='data_filler')
    #parser.add_argument('--s2e-ethernet-tests', const=True, default=False, action='store_const', help='Run through the suite of Serial to Ethernet tests using Telnet & Serial interfaces')
    
    args = parser.parse_args()
    return args
    
def handle_serial_tests( args, seed ):
    use_default_config = False
    
    verbose = 0
    prog_bar = 0
    log_file = None
    
    if args.verbose:
        verbose = 1
        
    if args.prog_bar:
        prog_bar = 1
        
    if args.log_file:
        log_file = args.log_file
        
    serial_test = XmosSerialTestSuite( "", verbose, prog_bar, log_file)

    test_count = 0
    test_pass = 0
            
    if args.config_strings is None:
        print "NOTE: Using default config for all UART settings"
        use_default_config = True
    elif len(args.config_strings) != len(args.ports_for_test):
        print "NOTE: Using default config for all UART settings"
        use_default_config = True
    
    if args.serial_echo_test:
        # simple echo test on all defined ports
        i = 0
        for port_id in args.ports_for_test:
            test_count += 1
            if use_default_config:
                config_string = "115200-8-E-1"
            else:
                config_string = args.config_strings[i]
            
            serial_test.set_port( port_id )
            test_pass += serial_test.simple_echo_test( config_string, seed, test_len=2048 )
            i += 1
    
    if args.serial_multi_speed_echo_test:    
        # test with reconfiguration on all defined ports - halves baud rate each time
        i = 0
        for port_id in args.ports_for_test:
            if use_default_config:
                config_string = "115200-8-E-1"
            else:
                config_string = args.config_strings[i]
            
            config = config_string.split("-")
            baud_rate = int(config[0])
            
            serial_test.set_port( port_id )
       
            while (baud_rate >= 225):
                test_count += 1
                built_config = str(baud_rate)+"-"+config[1]+"-"+config[2]+"-"+config[3]
                test_pass += serial_test.simple_echo_test( built_config, seed, reconfigure=True, test_len=2048 )
                baud_rate = baud_rate / 2
                
            i += 1
    
    if args.serial_burst_echo_test:
        # test on all defined ports
        i = 0
        for port_id in args.ports_for_test:
            test_count += 1
            if use_default_config:
                config_string = "115200-8-E-1"
            else:
                config_string = args.config_strings[i]
            
            serial_test.set_port( port_id )
            test_pass += serial_test.data_burst_test( config_string, seed, burst_len=100, test_len=2048 )
            i += 1
    
    if (test_count > 0):
        print "\n---------- Serial Tests Complete ----------"
        print "Run "+str(test_count)+" TEST(S) with "+str(test_pass)+" PASS and "+str(test_count-test_pass)+" FAILS"
        print "---------------------------------------------\n"
        
def handle_telnet_tests(args, seed):
    verbose = 0
    prog_bar = 0
    log_file = None
    
    if args.verbose:
        verbose = 1
        
    if args.prog_bar:
        prog_bar = 1
        
    if args.log_file:
        log_file = args.log_file
        
    telnet_test = XmosTelnetTestSuite("", "", verbose, prog_bar, log_file)
        
    test_count = 0
    test_pass = 0
    
    if args.app_start_up_check_using_telnet:
        test_name = "app_start_up_check_using_telnet"
        
        if args.telnet_targets is None:
            raise XmosTestException("Cannot run "+test_name+" test no targets specified")
        else:
            for target in args.telnet_targets:
                test_count += 1
                target_properties = target.split(':')
                if (len(target_properties) != 2):
                    raise XmosTestException("Cannot run "+test_name+" as invalid targets specified")
                
                telnet_test.set_target(target_properties[0], target_properties[1])
                test_pass += telnet_test.app_start_up_check_using_telnet()
    
    if args.app_maximum_connections_telnet:
        test_name = "app_maximum_connections_telnet"
        
        if args.telnet_targets is None:
            raise XmosTestException("Cannot run "+test_name+" test no targets specified")
        else:
            for target in args.telnet_targets:
                test_count += 1
                target_properties = target.split(':')
                if (len(target_properties) != 2):
                    raise XmosTestException("Cannot run "+test_name+" as invalid targets specified")
                    
                telnet_test.set_target(target_properties[0], target_properties[1])
                test_pass += telnet_test.app_maximum_connections_telnet()
                    
    if args.application_telnet_port_uart_data_check_echo_loop_back:
        test_name = "application_telnet_port_uart_data_check_echo_loop_back"
        test_duration_unit='cycles'
        test_duration=10
        
        if args.test_duration:
            test_duration = args.test_duration[0]
            test_duration_unit = args.test_duration[1] 
        
        if args.telnet_targets is None:
            raise XmosTestException("Cannot run "+test_name+" test no targets specified")
        else:
            for target in args.telnet_targets:
                test_count += 1
                target_properties = target.split(':')
                if (len(target_properties) != 2):
                    raise XmosTestException("Cannot run "+test_name+" as invalid targets specified")
                
                telnet_test.set_target(target_properties[0], target_properties[1])
                test_pass += telnet_test.application_telnet_port_uart_data_check_echo_loop_back(seed, test_duration=test_duration, test_duration_unit=test_duration_unit)
    
    if args.application_telnet_port_uart_data_check_cross_loop_back is not None:
        test_name = "application_telnet_port_uart_data_check_cross_loop_back"
        
        if args.test_duration:
            test_duration = args.test_duration[0]
            test_duration_unit = args.test_duration[1]
        
        for master,slave in pairwise(args.application_telnet_port_uart_data_check_cross_loop_back):
            test_count += 1
            
            master_target_properties = master.split(':')
            if (len(master_target_properties) != 2):
                raise XmosTestException("Cannot run "+test_name+" as invalid master target specified")
            
            slave_target_properties = slave.split(':')
            if (len(slave_target_properties) != 2):
                raise XmosTestException("Cannot run "+test_name+" as invalid slave target specified")
            
            telnet_test.set_target(master_target_properties[0], master_target_properties[1])
            test_pass += telnet_test.application_telnet_port_uart_data_check_cross_loop_back(seed, slave_target_properties[0], slave_target_properties[1], test_duration=test_duration, test_duration_unit=test_duration_unit)
    
    if args.application_telnet_read_write_command_check:
        test_name = "application_telnet_read_write_command_check"
        
        if args.telnet_conf_targets is None:
            raise XmosTestException("Cannot run "+test_name+" test as no configuration targets specified")
        
        for target in args.telnet_conf_targets:
            test_count += 1
            target_properties = target.split(':')
            if (len(target_properties) != 2):
                raise XmosTestException("Cannot run "+test_name+" as invalid configuration targets specified")
                
            telnet_test.set_target(target_properties[0], target_properties[1])
            test_pass += telnet_test.application_telnet_read_write_command_check()
            
    if (test_count > 0):
        print "\n------- Telnet Tests Complete -------"
        print "Run "+str(test_count)+" TEST(S) with "+str(test_pass)+" PASS and "+str(test_count-test_pass)+" FAILS"
        print "--------------------------------------\n"
    
def handle_s2e_tests(args, seed):
    
    verbose = 0
    prog_bar = 0
    log_file = None
    
    if args.verbose:
        verbose = 1
        
    if args.prog_bar:
        prog_bar = 1
        
    if args.log_file:
        log_file = args.log_file
        
    s2e_test = XmosSerialToEthernetSystemTests(prog_bar=prog_bar, log_file=log_file, verbose=verbose)
    
    test_count = 0
    test_pass = 0
    
    if args.data_filler:
        test_count += 1
        
        serial_target = args.data_filler[1]
        telnet_target = args.data_filler[0]
        telnet_target_properties = telnet_target.split(':')
        if (len(telnet_target_properties) != 2):
            raise XmosTestException("Cannot run "+test_name+" as invalid configuration targets specified")
        
        s2e_test.set_port( serial_target )
        s2e_test.set_target(telnet_target_properties[0], telnet_target_properties[1])
        test_pass += s2e_test.data_filler_serial_to_telnet(seed)
    
    if (test_count > 0):
        print "\n------- S2E System Tests Complete -------"
        print "Run "+str(test_count)+" TEST(S) with "+str(test_pass)+" PASS and "+str(test_count-test_pass)+" FAILS"
        print "-------------------------------------------\n"
        
def main():
    
    if platform.system() == 'Windows':
        print 'ERROR: Native Win32 not supported due to use of pexpect - please use cygwin (see README)'
        exit(1)
    
    args = process_args()
    
    if args.list_devices is True:
        list_com_ports()
        sys.exit(0)
    
    if args.seed is None:
        seed = random.randint(0,1000000)
    else:
        seed = args.seed
    
    print "---> Test Run with Seed = "+str(seed)
    
    try:
        handle_serial_tests( args, seed )
    except XmosTestException as e:
        print "ERROR: "+e.msg
        exit(1)
    except SerialException as e:
        print "ERROR: "+e.message
        exit(1)
        
    try:
        handle_telnet_tests(args, seed)
    except XmosTestException as e:
        print "ERROR: "+e.msg
        exit(1)
        
    try:
        handle_s2e_tests(args, seed)
    except XmosTestException as e:
        print "ERROR: "+e.msg
        exit(1)
    
if __name__ == "__main__":
    main()
    
        