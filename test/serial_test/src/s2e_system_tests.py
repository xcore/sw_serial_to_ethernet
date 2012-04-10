import serial
import datetime
import random
import pexpect
import re
from telnet_tests import XmosTelnetTest, XmosTelnetTestFailure
from serial_tests import XmosSerialTest, XmosSerialException

class XmosSerialToEthernetSystemTests(XmosTelnetTest, XmosSerialTest):
    
    def __init__(self, address=None, port=None, serial_dev=None, verbose=0, prog_bar=0, log_file=None):
        super(XmosSerialToEthernetSystemTests, self).__init__(prog_bar=prog_bar, log_file=log_file)
        self.set_target(address, port)
        self.set_port(serial_dev)
        self.verbose = verbose

    def data_filler_serial_to_telnet(self, seed, config_string='115200-8-E-1', test_len=60, len_unit='seconds', burst_len=16):
        """Data filler test that pipes data through serial->telnet"""
        
        test_state = self.TEST_PASS
        test_message=None
        test_name = "data-filler-serial-to-telnet"
        
        rx_fail = 0
        tx_attempts = 0
        
        self.pb_print_start_test_info(test_name, self.port_id, "Running test on port "+self.port_id+" with config "+config_string)
        random.seed(seed)
        
        try:
            # connect
            telnet = self.telnet_s2e_connect()
            uart = self.configure_uart( config_string )    
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        except XmosSerialException as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
            telnet.close()
        else:
            # do test
            init = 1
            while self.test_finish_condition(len_unit, test_len, init):
                init = 0
                write_buf = ""
                # generate buffer
                for b in range(0,burst_len):
                    c = random.randint(0,len(self.character_bank)-1)
                    write_buf += self.character_bank[c]
                
                # write data to UART    
                uart.write(write_buf)
                uart.flush()
                tx_attempts += 1
                
                # get data from telnet
                try:
                    telnet.expect(re.escape(write_buf), timeout=5)
                except pexpect.TIMEOUT:
                    rx_fail += 1
                
            test_message = "Serial data bursts sent: "+str(tx_attempts)+" Telnet RX Failures: "+str(rx_fail)
            if (rx_fail/tx_attempts > 0.1):
                test_state = self.TEST_FAIL
            else:
                test_state = self.TEST_PASS
            
            # close connection
            telnet.close()
            uart.close()
        
        self.print_test_info(test_name, test_state, self.port_id, test_message)
        self.test_cleanup()
        return test_state

def data_filler_telnet_to_serial(self, seed, config_string='115200-8-E-1', test_len=60, len_unit='seconds', burst_len=16):
        """Data filler test that pipes data through serial->telnet"""
        
        test_state = self.TEST_PASS
        test_message=None
        test_name = "data-filler-telnet-to-serial"
        
        rx_fail = 0
        tx_attempts = 0
        
        self.pb_print_start_test_info(test_name, self.port_id, "Running test on port "+self.port_id+" with config "+config_string)
        random.seed(seed)
        
        try:
            # connect
            telnet = self.telnet_s2e_connect()
            uart = self.configure_uart( config_string )    
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        except XmosSerialException as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
            telnet.close()
        else:
            # do test
            init = 1
            while self.test_finish_condition(len_unit, test_len, init):
                init = 0
                write_buf = ""
                # generate buffer
                for b in range(0,burst_len):
                    c = random.randint(0,len(self.character_bank)-1)
                    write_buf += self.character_bank[c]
                
                # write data to UART    
                uart.write(write_buf)
                uart.flush()
                tx_attempts += 1
                
                # get data from telnet
                try:
                    telnet.expect(re.escape(write_buf), timeout=5)
                except pexpect.TIMEOUT:
                    rx_fail += 1
                
                # time calculation
                current_time = datetime.datetime.now()
                delta = current_time - start_time
                self.update_prog_bar(getattr(delta, len_unit))
            
            test_message = "Serial data bursts sent: "+str(tx_attempts)+" Telnet RX Failures: "+str(rx_fail)
            if (rx_fail/tx_attempts > 0.1):
                test_state = self.TEST_FAIL
            else:
                test_state = self.TEST_PASS
            
            # close connection
            telnet.close()
            uart.close()
        
        self.print_test_info(test_name, test_state, self.port_id, test_message)
        self.test_cleanup()
        return test_state