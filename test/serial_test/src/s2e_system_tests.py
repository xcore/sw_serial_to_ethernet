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

    def data_filler(self, seed, config_string='115200-8-E-1', test_len=60, len_unit='seconds', burst_len=16):
        """Data filler test that pipes data through serial->telnet"""
        
        test_state = self.TEST_PASS
        test_message=None
        test_name = "data-filler-serial-to-telnet"
        
        serial_rx_fail = 0
        telnet_rx_fail = 0
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
                write_buf0 = ""
                write_buf1 = ""
                # generate buffer
                for b in range(0,burst_len):
                    c = random.randint(0,len(self.character_bank)-1)
                    write_buf0 += self.character_bank[c]
                    c = random.randint(0,len(self.character_bank)-1)
                    write_buf1 += self.character_bank[c]
                
                # write data to UART    
                uart.write(write_buf0)
                telnet.sendline(write_buf1)
                uart.flush()
                tx_attempts += 1
                
                # get data from telnet
                try:
                    telnet.expect(re.escape(write_buf0), timeout=5)
                except pexpect.TIMEOUT:
                    telnet_rx_fail += 1
                    
                # write data to telnet and check for it over UART
                read_buf = uart.read(len(write_buf1))
                if (read_buf != write_buf1):
                    serial_rx_fail += 1
                    
            test_message = "Data bursts sent: "+str(tx_attempts)+" Telnet RX Failures: "+str(telnet_rx_fail)+" Serial RX Failure: "+str(serial_rx_fail)
            if (telnet_rx_fail/tx_attempts > 0.1) or (serial_rx_fail/tx_attempts > 0.1):
                test_state = self.TEST_FAIL
            else:
                test_state = self.TEST_PASS
            
            # close connection
            telnet.close()
            uart.close()
        
        self.print_test_info(test_name, test_state, self.port_id, test_message)
        self.test_cleanup()
        return test_state

