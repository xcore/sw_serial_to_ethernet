import pexpect
import random
import datetime
import re
import sys

class XmosTelnetTestFailure(Exception):
    def __init__(self, msg):
        self.msg = msg
        
    def __str__(self):
        return repr(self.msg)
            
class XmosTelnetException(Exception):
    def __init__(self, msg):
        self.msg = msg
        
    def __str__(self):
        return repr(self.msg)
        
class XmosTelnetTest:
    """Base class for tests that utilise the telnet interface"""
    
    TEST_FAIL=0
    TEST_PASS=1
    character_bank="1234567890-=qwetyuiop[]asdfghjkl;'#\\zxcvbnm,./ !\"$%^&*()_+QWERTYUIOP{}ASDFGHJKL:@~|ZXCVBNM<>?"
    
    test_state = None
    test_message = ""
    
    def __init__(self, address, port, verbose=0):
        self.address = address
        self.port = port
        self.verbose = verbose
    
    def set_target( self, address, port ):
        self.address = address
        self.port = port
        
    def print_test_info(self, test_name, status, message=None):
        now = datetime.datetime.now()
        target = self.address+":"+self.port
        
        print "["+now.strftime("%d-%m-%Y %H:%M")+"] Test:",
        
        if status == self.TEST_FAIL:
            print test_name+" Target: "+target+" Result: FAIL"
            if message is not None:
                print "\tMessage: "+message
        if status == self.TEST_PASS:
            print test_name+" Target: "+target+" Result: PASS"
            if message is not None:
                print "\tMessage: "+message
    
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
            
        self.print_test_info(test_name, test_state, test_message)
        return test_state
        
    def application_telnet_port_uart_data_check_echo_loop_back(self, seed, test_len=20, lines=10):
        test_state = self.TEST_PASS
        test_message=None
        test_name = "application_telnet_port_uart_data_check_echo_loop_back"
        
        try:
            telnet_session = self.telnet_s2e_connect()
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            for line_count in range(0,lines):
                write_char = ""
                for i in range(0,test_len):
                    b = random.randint(0,len(self.character_bank)-1)
                    write_char += self.character_bank[b]
            
                try:
                    telnet_session.sendline(write_char)
                    # should get what we typed back twice due to telnet echo and uart echo
                    telnet_session.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                    telnet_session.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), test_len="+str(test_len)+", lines="+str(lines)+", current line="+str(line_count)
                
                if (test_state == self.TEST_FAIL):
                    break
                
            # close connection
            telnet_session.close()
        
        self.print_test_info(test_name, test_state, test_message)
        return test_state
    
    def application_telnet_port_uart_data_check_cross_loop_back(self, seed, second_addr, second_port, test_len=20, lines=10):
        test_state = self.TEST_PASS
        test_message=None
        test_name = "application_telnet_port_uart_data_check_cross_loop_back"
        
        try:
            telnet_session_master = self.telnet_s2e_connect()
            telnet_session_slave = self.telnet_s2e_connect(second_addr, second_port)
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            for line_count in range(0,lines):
                write_char = ""
                for i in range(0,test_len):
                    b = random.randint(0,len(self.character_bank)-1)
                    write_char += self.character_bank[b]
            
                try:
                    telnet_session_master.sendline(write_char)
                    # should get what we typed back twice due to telnet echo and uart echo
                    telnet_session_master.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                    telnet_session_slave.expect(re.escape(write_char), timeout=5) # ensure we expect a reg exp safe literal
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), test_len="+str(test_len)+", lines="+str(lines)+", current line="+str(line_count)
                
                if (test_state == self.TEST_FAIL):
                    break
                
            # close connection
            telnet_session_master.close()
            telnet_session_slave.close()
        
        self.print_test_info(test_name, test_state, test_message)
        return test_state
    
    def application_telnet_read_write_command_check(self, channel_count=8):
        test_state = self.TEST_PASS
        test_message = None
        test_name="application_telnet_read_write_command_check"
            
        try:
            telnet_session = self.telnet_s2e_connect()
        except XmosTelnetTestFailure as e:
            test_state = self.TEST_FAIL
            test_message = e.msg
        else:
            for chan_id in range(0,channel_count):
                try:
                    config_str = '#C#'+str(chan_id)+'#1#1#9600#5#0#102#@'
                    telnet_session.sendline(config_str)
                    telnet_session.expect('UART '+str(chan_id)+' settings successful', timeout=5)
                    telnet_session.sendline('#R#'+str(chan_id)+'#@')
                    telnet_session.expect(re.escape(config_str), timeout=5)
                    
                    config_str = '#C#'+str(chan_id)+'#2#0#115200#8#0#'+str(46+chan_id)+'#@'
                    telnet_session.sendline(config_str)
                    telnet_session.expect('UART '+str(chan_id)+' settings successful', timeout=5)
                    telnet_session.sendline('#R#'+str(chan_id)+'#@')
                    telnet_session.expect(re.escape(config_str), timeout=5)
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), config_str = "+config_str+", chan_id = "+str(chan_id)
                    break
                
            # close connection
            telnet_session.close()
                
        self.print_test_info(test_name, test_state, test_message)
        return test_state
                    
                    