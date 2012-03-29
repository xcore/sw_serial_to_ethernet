import argparse
import sys
import progressBar
import random
import time
import serial_tests
import telnet_tests
import serial.tools.list_ports as list_ports

class TestException(Exception):
    def __init__(self, msg):
        self.msg = msg
        
    def __str__(self):
        return self.msg

def list_com_ports():
    print "Available Serial ports - "
    for port in list_ports.comports():
        print "\t"+port[0]

        
def process_args():
    parser = argparse.ArgumentParser(description='XMOS UART Testing System')
    
    parser.add_argument('-l', '--list-devices', action='store_const', const=True, default=False, help='List available UARTs on this system')
    
    parser.add_argument('-t', nargs='+', help='List of UARTs to test (see -l to obtain a full list of available ports)', dest='ports_for_test')
    
    parser.add_argument('-c', nargs='+', help='List of configurations in the format baud-bits-parity-stop_bits e.g for 115200 bps with 8 bit characters, even parity and 1 stop bit you would use 115200-8-E-1. Valid parity is N-none, M-mark, S-space, E-even, O-odd. Default configurations will be 115200-8-E-1', dest='config_strings')
    
    parser.add_argument('-n', nargs='+', help='List of telnet configurations in the format address:port', dest='telnet_targets')
    
    parser.add_argument('-s', '--seed', help='Integer seed for psuedo random tests - if not given then a random seed will be used and reported', dest='seed', type=int)
    
    parser.add_argument('--log', nargs=1, help='File name for failure logging', dest='log_file')
    
    parser.add_argument('--echo-test', action='store_const', const=True, default=False, help='Do the simple echo test at a single speed')
    
    parser.add_argument('--multi-speed-echo-test', const=True, default=False, action='store_const', help='Do the simple echo test at multiple speeds using the auto-reconfiguration command to halve the baud rate')

    parser.add_argument('--burst-echo-test', const=True, default=False, action='store_const', help='Do the simple burst test at a single speed')
    
    parser.add_argument('--multi-speed-burst-echo-test', const=True, default=False, action='store_const', help='Do the burst test at multiple speeds using the auto-reconfiguration command to halve the baud rate')
    
    parser.add_argument('--app-start-up-check-using-telnet', const=True, default=False, action='store_const', help='Run app_start_up_check_using_telnet test')
    
    parser.add_argument('--app-maximum-connections-telnet', const=True, default=False, action='store_const', help='Run app_maximum_connections_telnet test')
    
    parser.add_argument('--application-telnet-port-uart-data-check-echo-loop-back', const=True, default=False, action='store_const', help='Run application_telnet_port_uart_data_check_echo_loop_back test')
    
    #parser.add_argument('--s2e-ethernet-tests', const=True, default=False, action='store_const', help='Run through the suite of Serial to Ethernet tests using Telnet & Serial interfaces')
    
    args = parser.parse_args()
    return args
    
def handle_serial_tests( args, seed ):
    use_default_config = False
    
    if args.config_strings is None:
        print "NOTE: Using default config for all UART settings"
        use_default_config = True
    elif len(args.config_strings) != len(args.ports_for_test):
        print "NOTE: Using default config for all UART settings"
        use_default_config = True
    
    st1 = XmosSerialTestSuite( "" )
    
    if args.echo_test:
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
        print "Simple Echo Tests..."
        # simple echo test on all defined ports
        i = 0
        for port_id in args.ports_for_test:
            if use_default_config:
                config_string = "115200-8-E-1"
            else:
                config_string = args.config_strings[i]
            
            st1.set_port( port_id )
            st1.simple_echo_test( config_string, seed, test_len=2048 )
            i += 1
    
    if args.multi_speed_echo_test:    
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
        print "Multi-Speed Echo Tests using echo server reconfiguration..."
        # test with reconfiguration on all defined ports - halves baud rate each time
        i = 0
        for port_id in args.ports_for_test:
            if use_default_config:
                config_string = "115200-8-E-1"
            else:
                config_string = args.config_strings[i]
            
            config = config_string.split("-")
            baud_rate = int(config[0])
            
            st1.set_port( port_id )
       
            while (baud_rate >= 225):
                built_config = str(baud_rate)+"-"+config[1]+"-"+config[2]+"-"+config[3]
                st1.simple_echo_test( built_config, seed, reconfigure=True, test_len=2048 )
                baud_rate = baud_rate / 2
       
            i += 1
    
    if args.burst_test:
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
        print "Burst Echo Test..."
        # test on all defined ports
        i = 0
        for port_id in args.ports_for_test:
            if use_default_config:
                config_string = "115200-8-E-1"
            else:
                config_string = args.config_strings[i]
            
            lf = None
            if args.log_file is not None:
                lf = args.log_file[0]
            
            st1.set_port( port_id )
            st1.data_burst_test( config_string, seed, burst_len=1024, test_len=500, log_file=lf )
            i += 1
        
        
    if args.multi_speed_burst_test:
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
        print "NOT IMPLEMENTED"
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
    
def handle_telnet_tests(args, seed):
    
    telnet_test = telnet_tests.XmosTelnetTest("","")
    
    test_count = 0
    test_pass = 0
    
    if args.app_start_up_check_using_telnet:
        test_count += 1
        test_name = "app_start_up_check_using_telnet"
        
        if args.telnet_targets is None:
            raise TestException("Cannot run "+test_name+" test no targets specified")
        else:
            for target in args.telnet_targets:
                target_properties = target.split(':')
                if (len(target_properties) != 2):
                    TestException("Cannot run "+test_name+" as invalid targets specified")
                
                telnet_test.set_target(target_properties[0], target_properties[1])
                test_pass += telnet_test.app_start_up_check_using_telnet()
    
    if args.app_maximum_connections_telnet:
        test_count += 1
        test_name = "app_maximum_connections_telnet"
        
        if args.telnet_targets is None:
            raise TestException("Cannot run "+test_name+" test no targets specified")
        else:
            for target in args.telnet_targets:
                target_properties = target.split(':')
                if (len(target_properties) != 2):
                    TestException("Cannot run "+test_name+" as invalid targets specified")
                    
                telnet_test.set_target(target_properties[0], target_properties[1])
                test_pass += telnet_test.app_maximum_connections_telnet()
                    
    if args.application_telnet_port_uart_data_check_echo_loop_back:
        test_count += 1
        test_name = "application_telnet_port_uart_data_check_echo_loop_back"
        
        if args.telnet_targets is None:
            raise TestException("Cannot run "+test_name+" test no targets specified")
        else:
            for target in args.telnet_targets:
                target_properties = target.split(':')
                if (len(target_properties) != 2):
                    TestException("Cannot run "+test_name+" as invalid targets specified")
                
                telnet_test.set_target(target_properties[0], target_properties[1])
                test_pass += telnet_test.application_telnet_port_uart_data_check_echo_loop_back(seed)
                
    if (test_count > 0):
        print "\nTelnet Tests Complete"
        print "Run "+str(test_count)+" TEST(S) with "+str(test_pass)+" PASS and "+str(test_count-test_pass)+" FAILS"
    
def main():
    args = process_args()
    
    if args.list_devices is True:
        list_com_ports()
        sys.exit(0)
    
    if args.seed is None:
        seed = random.randint(0,1000000)
    else:
        seed = args.seed
    
    try:
        handle_telnet_tests(args, seed)
    except TestException as e:
        print "ERROR: "+e.msg
        exit(1)
    
    
if __name__ == "__main__":
    main()
    
        