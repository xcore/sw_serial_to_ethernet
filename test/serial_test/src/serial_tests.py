import serial

class XmosSerialTestFailure(Exception):
        def __init__(self, msg):
            self.msg = msg
       
        def __str__(self):
            return repr(self.msg)

class XmosSerialException(Exception):
        def __init__(self, msg):
            self.msg = msg
       
        def __str__(self):
            return repr(self.msg)

class XmosSerialTest:
    """Base class for tests that utilise the serial port"""
    
    def __init__(self, port_id):
        self.__port_id = port_id
    
    def set_port( self, port_id ):
        self.__port_id = port_id
    
    def configure_uart( self, config_string ):
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
            raise XmosSerialException("ERROR: Invalid bit size for configuration of "+self.__port_id)
            
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
            raise XmosSerialException("ERROR: Invalid parity setting for configuration of "+self.__port_id)
            
        if (config_parts[3] == '1'):
            sb = serial.STOPBITS_ONE 
        elif (config_parts[3] == '1.5'):
            sb = serial.STOPBITS_ONE_POINT_FIVE
        elif (config_parts[3] == '2'):     
            sb = serial.STOPBITS_TWO
        else:
            raise XmosSerialException("ERROR: Invalid stop bit setting for configuration of "+self.__port_id)
            
        # setup UART as configuration requires, with a timeout of 2s
        uart = serial.Serial(port=self.__port_id, baudrate=baud, bytesize=char_size, parity=par, stopbits=sb, timeout=2)
        
        return uart

class XmosSerialTestSuite(XmosSerialTest):
    """This class provides pure serial tests for the UART module. It relies on the echo application"""
    
    def simple_echo_test( self, config_string, seed, test_len=1024, reconfigure=False, log_file=None ):
        """Conduct a simple echo test sending psuedo random data chars one at a time and """
        
        # 'r' is deliberately not in this list as it will cause the echo server to reconfigure the UART
        characters = "1234567890-=qwetyuiop[]asdfghjkl;'#\\zxcvbnm,./ !\"$%^&*()_+QWERTYUIOP{}ASDFGHJKL:@~|ZXCVBNM<>?"
        
        print "\n------------------------------------------------------"
        print "Running SIMPLE ECHO test on port "+self.__port_id+" with config "+config_string
        
        uart = configure_uart( self.__port_id, config_string )    
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
    
    def data_burst_test( self, config_string, seed, test_len=16, reconfigure=False, burst_len=3, log_file=None):
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
        print "Running BURST DATA test on port "+self.__port_id+" with config "+config_string
        
        uart = configure_uart( port_id, config_string )    
        print port_id+" configured"
        
        print "Using seed "+str(seed)
        random.seed(seed)
        
        print "Waiting for the UART to make sense... sending 'A'"
        uart.write("A")
        uart.flush()
        sys.stdout.write(".")
        while (uart.read() != "A"):
            uart.write("A")
            uart.flush()
            sys.stdout.write(".")
            sys.stdout.flush()
            
        print "Cleaning up UART buffers"
        while uart.read() != "":
            print "."
            
        print ""
        print "Running test - "+str(test_len)+" lots of "+str(burst_len)+" byte bursts..."
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
                uart.flush()
                
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
            
            # clean out input buffer to ensure things aren't out of sync
            uart.flushInput()
            
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
