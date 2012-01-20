import serial
import serial.tools.list_ports as list_ports
import argparse
import sys
import progressBar
import random
import time

def list_com_ports():
    
    print "Available Serial ports - "
    for port in list_ports.comports():
        print "\t"+port[0]
        
def print_help():
    print "XMOS UART Testing System"
    
def process_args():
    parser = argparse.ArgumentParser(description='XMOS UART Testing System')
    
    parser.add_argument('-l', '--list-devices', action='store_const', const=True, default=False, help='List available UARTs on this system')
    
    parser.add_argument('-t', nargs='+', help='List of UARTs to test (see -l to obtain a full list of available ports)', dest='ports_for_test')
    
    parser.add_argument('-c', nargs='+', help='List of configurations in the format baud-bits-parity-stop_bits e.g for 115200 bps with 8 bit characters, even parity and 1 stop bit you would use 115200-8-E-1. Valid parity is N-none, M-mark, S-space, E-even, O-odd. Default configurations will be 115200-8-E-1', dest='config_strings')
    
    parser.add_argument('-s', '--seed', help='Integer seed for psuedo random tests - if not given then a random seed will be used and reported', dest='seed', type=int)
    
    parser.add_argument('--echo-test', action='store_const', const=True, default=False, help='Do the simple echo test at a single speed')
    
    parser.add_argument('--multi-speed-echo-test', const=True, default=False, action='store_const', help='Do the simple echo test at multiple speeds using the auto-reconfiguration command to halve the baud rate')

    parser.add_argument('--burst-test', const=True, default=False, action='store_const', help='Do the simple burst test at a single speed')
    
    parser.add_argument('--multi-speed-burst-test', const=True, default=False, action='store_const', help='Do the burst test at multiple speeds using the auto-reconfiguration command to halve the baud rate')
    
    parser.add_argument('--log', nargs=1, help='File name for failure logging', dest='log_file')

    args = parser.parse_args()
    return args

def configure_uart( port_id, config_string ):
    """Configure a UART port according to the configuration that was entered at the command line, default config will be 115200-8-E-1"""
    
    config_parts = config_string.split('-')
    
    baud = int(config_parts[0])
    #TODO verify baud is in allowed list
    
    if (int(config_parts[1])) == 5:
        char_size = serial.FIVEBITS
    elif (int(config_parts[1])) == 6:
        char_size = serial.SIXBITS
    elif (int(config_parts[1])) == 7:    
        char_size = serial.SEVENBITS
    elif (int(config_parts[1])) == 8:
        char_size = serial.EIGHTBITS
    else:
        sys.exit("ERROR: Invalid bit size for configuration of "+port_id)
        
    if (config_parts[2] == 'N' or config_parts[2] == 'n'):
        par = serial.PARITY_NONE
    elif (config_parts[2] == 'E' or config_parts[2] == 'e'):
        par = serial.PARITY_EVEN
    elif (config_parts[2] == 'O' or config_parts[2] == 'o'):
        par = serial.PARITY_ODD 
    elif (config_parts[2] == 'M' or config_parts[2] == 'm'):
        par = serial.PARITY_MARK
    elif (config_parts[2] == 'S' or config_parts[2] == 's'):
        par = serial.PARITY_SPACE
    else:
        sys.exit("ERROR: Invalid parity setting for configuration of "+port_id)
    
    if (config_parts[3] == '1'):
        sb = serial.STOPBITS_ONE 
    elif (config_parts[3] == '1.5'):
        sb = serial.STOPBITS_ONE_POINT_FIVE
    elif (config_parts[3] == '2'):     
        sb = serial.STOPBITS_TWO
    else:
        sys.exit("ERROR: Invalid stop bit setting for configuration of "+port_id)
    
    # setup UART as configuration requires, with a timeout of 2s
    uart = serial.Serial(port=port_id, baudrate=baud, bytesize=char_size, parity=par, stopbits=sb, timeout=2)
    
    return uart

def simple_echo_test( port_id, config_string, seed, test_len=1024, reconfigure=False, log_file=None ):
    """Conduct a simple echo test sending psuedo random data chars one at a time and """
    
    # 'r' is deliberately not in this list as it will cause the echo server to reconfigure the UART
    characters = "1234567890-=qwetyuiop[]asdfghjkl;'#\\zxcvbnm,./ !\"$%^&*()_+QWERTYUIOP{}ASDFGHJKL:@~|ZXCVBNM<>?"

    print "\n------------------------------------------------------"
    print "Running SIMPLE ECHO test on port "+port_id+" with config "+config_string
    
    uart = configure_uart( port_id, config_string )    
    print port_id+" configured"
    
    print "Using seed "+str(seed)
    random.seed(seed)
    
    print "Waiting for the UART to make sense... sending 'A'"
    uart.write("A")
    sys.stdout.write(".")
    while (uart.read() != "A"):
        uart.write("A")
        sys.stdout.write(".")
        sys.stdout.flush()
    
    print "Cleaning up UART buffers"
    uart.flush()
    time.sleep(5)
    uart.flushInput()
    
    print ""
    print "Running test..."
    pb = progressBar.progressBar(0,test_len,20)
    char_ok = 0
    char_fail = 0
    
    for i in range(0,test_len):
        
        b = random.randint(0,len(characters)-1)
        write_char = characters[b]
        uart.write(write_char)
        read_char = uart.read(1)
        if ( read_char == write_char):
            char_ok += 1
        else:
            char_fail += 1
            print "\nFAILURE => write_char = "+write_char+"\tread_char = "+read_char
        
        if ((i % int(test_len/20)) == 0):
            pb.updateAmount(i)
            sys.stdout.write(str(pb)+"COMPLETED: "+str(i)+" of "+str(test_len)+" PASS: "+str(char_ok)+" FAIL: "+str(char_fail)+"\r")
            sys.stdout.flush()
    
    pb.updateAmount(test_len)
    sys.stdout.write(str(pb)+"COMPLETED: "+str(test_len)+" of "+str(test_len)+" PASS: "+str(char_ok)+" FAIL: "+str(char_fail)+"\n")
    
    sys.stdout.write("Simple Echo Test COMPLETED => ")
    if (char_fail == 0):
        sys.stdout.write("PASS")
        retval = 0
    else:
        sys.stdout.write("FAIL")
        retval = 1
        
    sys.stdout.flush()
    
    if reconfigure:
        print "\nDoing reconfiguration stage..."
        uart.write("r")
        uart.read()
        
    uart.close()
    print "\n------------------------------------------------------"
    return retval
    
def data_burst_test( port_id, config_string, seed, test_len=16, reconfigure=False, burst_len=3, log_file=None):
    """Generate bursts of data of a defined length and check that all data is echoed correctly """
    
    # 'r' is deliberately not in this list as it will cause the echo server to reconfigure the UART
    characters = "1234567890-=qwetyuiop[]asdfghjkl;'#\\zxcvbnm,./ !\"$%^&*()_+QWETYUIOP{}ASDFGHJKL:@~|ZXCVBNM<>?"
    
    log_f = None
    if log_file is not None:
        log_f = open(log_file, 'w')
        log_f.write("------------------------------------------------------\n")
        log_f.write("BURST DATA TEST FAILURE LOG\n")
        log_f.write("------------------------------------------------------\n")
        log_f.flush()

    print "\n------------------------------------------------------"
    print "Running BURST DATA test on port "+port_id+" with config "+config_string
    
    uart = configure_uart( port_id, config_string )    
    print port_id+" configured"
    
    print "Using seed "+str(seed)
    random.seed(seed)
    
    print "Waiting for the UART to make sense... sending 'A'"
    uart.write("A")
    sys.stdout.write(".")
    while (uart.read() != "A"):
        uart.write("A")
        sys.stdout.write(".")
        sys.stdout.flush()
    
    print "Cleaning up UART buffers"
    uart.flush()
    time.sleep(5)
    uart.flushInput()
    
    print ""
    print "Running test..."
    pb = progressBar.progressBar(0,test_len,20)
    burst_ok = 0
    burst_fail = 0
    
    for i in range(0,test_len):
        write_buf = ""
        # generate buffer
        for b in range(0,burst_len):
            c = random.randint(0,len(characters)-1)
            write_buf += characters[c]
        uart.write(write_buf)
        
        # read buffer and compare
        read_buf = uart.read(len(write_buf))
        if (read_buf != write_buf):
            if log_f is not None:
                log_f.write(">>> FAILURE on interation "+str(i)+"\n")
                log_f.write("write_buf = "+write_buf+"\n")
                log_f.write("read_buf  = "+read_buf+"\n")
                log_f.flush()
            burst_fail += 1
        else:
            burst_ok += 1
            
        pb.updateAmount(i)
        sys.stdout.write(str(pb)+"COMPLETED: "+str(i+1)+" of "+str(test_len)+" PASS: "+str(burst_ok)+" FAIL: "+str(burst_fail)+"\r")
        sys.stdout.flush()
    
    sys.stdout.write("\nBURST TEST COMPLETED => ")
    if (burst_fail == 0):
        sys.stdout.write("PASS")
        retval = 0
    else:
        sys.stdout.write("FAIL")
        retval = 1
        
    sys.stdout.flush()
    
    if reconfigure:
        print "\nDoing reconfiguration stage..."
        uart.write("r")
        uart.read()
        
    if log_f is not None:
        log_f.close()
        
    uart.close()
    print "\n------------------------------------------------------"
    return retval

def main():
    use_default_config = False
    args = process_args()
    print args
    
    if args.list_devices is True:
        list_com_ports()
        sys.exit(0)
    
    if args.config_strings is None:
        print "NOTE: Using default config for all UART settings"
        use_default_config = True
    elif len(args.config_strings) != len(args.ports_for_test):
        print "NOTE: Using default config for all UART settings"
        use_default_config = True
        
    if args.seed is None:
        seed = random.randint(0,1000000)
    else:
        seed = args.seed
    
    
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
            
            simple_echo_test( port_id, config_string, seed, test_len=2048 )
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
       
            while (baud_rate >= 225):
                built_config = str(baud_rate)+"-"+config[1]+"-"+config[2]+"-"+config[3]
                simple_echo_test( port_id, built_config, seed, reconfigure=True, test_len=2048 )
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
                
            data_burst_test( port_id, config_string, seed, burst_len=3, test_len=2048, log_file=lf )
            i += 1
        
        
    if args.multi_speed_burst_test:
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
        print "NOT IMPLEMENTED"
        print "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
        
        
        
if __name__ == "__main__":
    main()
    
        