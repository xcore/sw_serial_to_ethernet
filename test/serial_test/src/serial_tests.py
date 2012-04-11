import serial
import sys
import random
import time
from xmos_test import XmosTest, XmosTestException

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

class XmosSerialTest(XmosTest):
    """Base class for tests that utilise the serial port"""
    
    def __init__(self, port_id="", verbose=0, prog_bar=0, log_file=None):
        super(XmosSerialTest, self).__init__(prog_bar=prog_bar, log_file=log_file)
        self.port_id = port_id
    
    def set_port( self, port_id):
        self.port_id = port_id
    
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
        uart = serial.Serial(port=self.port_id, baudrate=baud, bytesize=char_size, parity=par, stopbits=sb, timeout=2)
        
        return uart

class XmosSerialTestSuite(XmosSerialTest):
    """This class provides pure serial tests for the UART module. It relies on the echo application"""
    
    def simple_echo_test( self, config_string, seed, test_len=1024, test_duration_unit='cycles', reconfigure=False, log_file=None ):
        """Conduct a simple echo test sending psuedo random data chars one at a time and """
        
        test_state = self.TEST_PASS
        test_message=None
        test_name = "serial_echo_test"
        
        self.pb_print_start_test_info(test_name, self.port_id, "Running SIMPLE ECHO test on port "+self.port_id+" with config "+config_string)
        
        try:
            uart = self.configure_uart( config_string )    
            random.seed(seed)
            
            self.print_to_log(test_name, "Initialising...")
            uart.write("A")
            count = 0
            while (uart.read() != "A"):
                uart.write("A")
                count += 1
                if count > 10:
                    raise XmosTestException("Did not get initialisation character \"A\"")
                
            uart.flush()
            time.sleep(5)
            uart.flushInput()
            
            test_count = 0
            char_ok = 0
            char_fail = 0
            
            init = 1
            while self.test_finish_condition(test_duration_unit, test_len, init ):
                test_count += 1
                init = 0
                b = random.randint(0,len(self.character_bank)-1)
                write_char = self.character_bank[b]
                uart.write(write_char)
                read_char = uart.read(1)
                if ( read_char == write_char):
                    char_ok += 1
                else:
                    char_fail += 1
                    self.print_to_log(test_name, "\nFAILURE => write_char = "+write_char+"\tread_char = "+read_char)
                    
            if (char_fail == 0):
                test_state = self.TEST_PASS
            else:
                test_state = self.TEST_FAIL
                
            test_message = "Configuration = "+config_string+" COMPLETED: "+str(test_count)+" PASS: "+str(char_ok)+" FAIL: "+str(char_fail)+"\n"
            
            if reconfigure:
                self.print_to_log(test_name, "\nDoing reconfiguration stage...")
                uart.write("r")
                uart.read()
        
        except XmosTestException as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
            
        uart.close()
        self.print_test_info(test_name, test_state, self.port_id, test_message)
        self.test_cleanup()
        return test_state
    
    def data_burst_test( self, config_string, seed, test_len=16, test_duration_unit='cycles', reconfigure=False, burst_len=3, log_file=None):
        """Generate bursts of data of a defined length and check that all data is echoed correctly """
        
        test_state = self.TEST_PASS
        test_message=None
        test_name = "serial_burst_echo_test"
        
        self.pb_print_start_test_info(test_name, self.port_id, "Running test on port "+self.port_id+" with config "+config_string)
        
        try:
            uart = self.configure_uart( config_string )    
            random.seed(seed)
            
            self.print_to_log(test_name, "Initialising...")
            uart.write("A")
            count = 0
            while (uart.read() != "A"):
                uart.write("A")
                count += 1
                if count > 10:
                    raise XmosTestException("Did not get initialisation character \"A\"")
                
            uart.flush()
            time.sleep(5)
            uart.flushInput()
            
            test_count = 0
            burst_ok = 0
            burst_fail = 0
            
            init = 1
            while self.test_finish_condition(test_duration_unit, test_len, init):
                init = 0
                write_buf = ""
                test_count += 1
                # generate buffer
                for b in range(0,burst_len):
                    c = random.randint(0,len(self.character_bank)-1)
                    write_buf += self.character_bank[c]
                    
                uart.write(write_buf)
                uart.flush()
                    
                # read buffer and compare
                read_buf = uart.read(len(write_buf))
                if (read_buf != write_buf):
                    self.print_to_log(test_name, ">>> FAILURE on interation "+str(i)+"\n")
                    self.print_to_log(test_name, "write_buf = "+write_buf+"\n")
                    self.print_to_log(test_name, "read_buf  = "+read_buf+"\n")
                    burst_fail += 1
                else:
                    burst_ok += 1
                        
                # clean out input buffer to ensure things aren't out of sync
                uart.flushInput()
                
            if (burst_fail == 0):
                test_state = self.TEST_PASS
            else:
                test_state = self.TEST_FAIL
                
            test_message = "Configuration = "+config_string+" COMPLETED: "+str(test_count)+" PASS: "+str(burst_ok)+" FAIL: "+str(burst_fail)+"\n"
            
            if reconfigure:
                self.print_to_log(test_name, "\nDoing reconfiguration stage...")
                uart.write("r")
                uart.read()
                
        except XmosTestException as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
            
        uart.close()
        self.print_test_info(test_name, test_state, self.port_id, test_message)
        self.test_cleanup()
        return test_state
    
        
