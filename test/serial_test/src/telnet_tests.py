import random
import datetime
import re
import sys
from xmos_test import XmosTest
import pexpect

class XmosTelnetTestFailure(Exception):
    def __init__(self, msg):
        self.msg = msg
        
    def __str__(self):
        return repr(self.msg)
            
class XmosTelnetTest(XmosTest):
    """Base class for tests that utilise the telnet interface"""
    
    def __init__(self, address="", port="", verbose=0, prog_bar=0, log_file=None):
        super(XmosTelnetTest, self).__init__(prog_bar=prog_bar, log_file=log_file)
        self.address = address
        self.port = port
        self.verbose = verbose
    
    def set_target( self, address, port ):
        self.address = address
        self.port = port
        
    def telnet_s2e_connect(self, address=None, port=None):
        if (self.verbose):
            log_location = sys.stdout
        else:
            log_location = None
        
        if (address is None or port is None ):
            address = self.address
            port = self.port
        
        # connect
        try:
            telnet_session = pexpect.spawn('telnet '+address+' '+port, logfile=log_location)
        except pexpect.EOF:
            raise XmosTelnetTestFailure("Invalid target - "+address+' '+port)
            
        # check for welcome
        try:
            #telnet_session.expect("Trying "+self.address+"...", timeout=5)
            #telnet_session.expect("Connected to "+self.address+".", timeout=5)
            #telnet_session.expect("Escape character is '^]'.", timeout=5)
            telnet_session.sendline("")
            telnet_session.expect("Welcome to serial to ethernet telnet server demo!", timeout=5)
            telnet_session.expect("(This server config acts as echo server...)", timeout=5)
        except pexpect.TIMEOUT as e:
            telnet_session.close()
            raise XmosTelnetTestFailure("Did not get correct connection response (timeout=5)")
        except pexpect.EOF:
            telnet_session.close()
            raise XmosTelnetTestFailure("Connection refused or close by remote host")
        else:
            return telnet_session

class XmosTelnetTestSuite(XmosTelnetTest):    
    def app_start_up_check_using_telnet(self):
        test_state = self.TEST_PASS
        test_message=None
        test_name = "app_start_up_check_using_telnet"
        
        try:
            telnet_session = self.telnet_s2e_connect()
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            # close connection
            telnet_session.close()
        
        self.print_test_info(test_name, test_state, test_message)
        self.test_cleanup()
        return test_state
        
    def app_maximum_connections_telnet(self):
        # this test never 'fails' - just measures how many connections work
        test_state = self.TEST_PASS
        test_message=None
        test_name = "app_maximum_connections_telnet"
        
        loop = 1
        count = 0
        telnet_session_list = []
        
        #open up as many sessions on this port as we can
        while (loop):
            try:
                telnet_session_list.append(self.telnet_s2e_connect())
            except XmosTelnetTestFailure:
                test_message = "Achieved "+str(count)+" connections"
                loop = 0
            else:
                count += 1
        
        #cleanup sessions
        for session in telnet_session_list:
            session.close()
        
        #ascertain if we passed
        if (count < 1):
            test_state = self.TEST_FAIL
            
        self.print_test_info(test_name, test_state, self.address+":"+self.port, test_message)
        self.test_cleanup()
        return test_state
        
    def application_telnet_port_uart_data_check_echo_loop_back(self, seed, data_len=20, test_duration=10, test_duration_unit='cycles'):
        test_state = self.TEST_PASS
        test_message=None
        test_name = "application_telnet_port_uart_data_check_echo_loop_back"
        
        self.pb_print_start_test_info(test_name, self.address+":"+self.port, "Running test for "+str(test_duration)+" "+test_duration_unit)
        
        try:
            telnet_session = self.telnet_s2e_connect()
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            init = 1
            lines = 0
            while self.test_finish_condition(test_duration_unit, test_duration, init):
                init=0
                lines += 1
                write_char = ""
                for i in range(0,data_len):
                    b = random.randint(0,len(self.character_bank)-1)
                    write_char += self.character_bank[b]
                
                try:
                    telnet_session.sendline(write_char)
                    # should get what we typed back twice due to telnet echo and uart echo
                    telnet_session.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                    telnet_session.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), lines="+str(lines)
                
                if (test_state == self.TEST_FAIL):
                    break
                
            # close connection
            telnet_session.close()
        
        self.print_test_info(test_name, test_state, self.address+":"+self.port, test_message)
        self.test_cleanup()
        return test_state
    
    def application_telnet_port_uart_data_check_cross_loop_back(self, seed, second_addr, second_port, data_len=20, test_duration=10, test_duration_unit='cycles'):
        test_state = self.TEST_PASS
        test_message=None
        test_name = "application_telnet_port_uart_data_check_cross_loop_back"
        
        self.pb_print_start_test_info(test_name, self.address+":"+self.port, "Running test for "+str(test_duration)+" "+test_duration_unit)
        
        try:
            telnet_session_master = self.telnet_s2e_connect()
            telnet_session_slave = self.telnet_s2e_connect(second_addr, second_port)
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            init = 1
            lines = 0
            while self.test_finish_condition(test_duration_unit, test_duration, init):
                init=0
                lines += 1
                write_char = ""
                for i in range(0,data_len):
                    b = random.randint(0,len(self.character_bank)-1)
                    write_char += self.character_bank[b]
            
                try:
                    telnet_session_master.sendline(write_char)
                    # should get what we typed back twice due to telnet echo and uart echo
                    telnet_session_master.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                    telnet_session_slave.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), lines="+str(lines)
                
                if (test_state == self.TEST_FAIL):
                    break
                
            # close connection
            telnet_session_master.close()
            telnet_session_slave.close()
        
        self.print_test_info(test_name, test_state, self.address+":"+self.port+" "+second_addr+":"+second_port, test_message)
        self.test_cleanup()
        return test_state
    
    def application_telnet_read_write_command_check(self, channel_count=8):
        test_state = self.TEST_PASS
        test_message = None
        test_name="application_telnet_read_write_command_check"
        stage = 0
        try:
            telnet_session = self.telnet_s2e_connect()
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            for chan_id in range(0,channel_count):
                stage = 0
                try:
                    config_str = '#C#'+str(chan_id)+'#1#1#9600#5#0#102#@'
                    telnet_session.sendline(config_str)
                    telnet_session.expect('UART '+str(chan_id)+' settings successful', timeout=5)
                    stage = 1
                    telnet_session.sendline('#R#'+str(chan_id)+'#@')
                    telnet_session.expect(re.escape(config_str), timeout=5)
                    stage = 2
                    
                    config_str = '#C#'+str(chan_id)+'#2#0#115200#8#0#'+str(46+chan_id)+'#@'
                    telnet_session.sendline(config_str)
                    telnet_session.expect('UART '+str(chan_id)+' settings successful', timeout=5)
                    stage = 3
                    telnet_session.sendline('#R#'+str(chan_id)+'#@')
                    telnet_session.expect(re.escape(config_str), timeout=5)
                    stage = 4
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), config_str = "+config_str+", chan_id = "+str(chan_id)+", stage = "+str(stage)
                    break
                
            # close connection
            telnet_session.close()
                
        self.print_test_info(test_name, test_state, self.address+":"+self.port, test_message)
        self.test_cleanup()
        return test_state
                    
                    