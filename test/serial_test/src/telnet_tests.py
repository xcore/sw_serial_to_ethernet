import pexpect
import random
import datetime

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
    
    def __init__(self, address, port):
        self.address = address
        self.port = port
    
    def set_target( self, address, port ):
        self.address = address
        self.port = port
        
    def print_test_info(self, test_name, status, message=None):
        now = datetime.datetime.now()
        print "["+now.strftime("%d-%m-%Y %H:%M")+"] Test:",
        
        if status == self.TEST_FAIL:
            print test_name+" Result: FAIL"
            if message is not None:
                print "\tMessage: "+message
        if status == self.TEST_PASS:
            print test_name+" Result: PASS"
            if message is not None:
                print "\tMessage: "+message
    
    def telnet_s2e_connect(self):
        # connect
        try:
            telnet_session = pexpect.spawn('telnet '+self.address+' '+self.port)
        except pexpect.EOF:
            raise XmosTelnetTestFailure("Invalid target - "+self.address+' '+self.port)
            
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
                test_message = "Failed after "+str(count)+" connections"
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
        
    def application_telnet_port_uart_data_check_echo_loop_back(self, seed, test_len=50, lines=10):
        test_state = self.TEST_PASS
        test_message=None
        test_name = "application_telnet_port_uart_data_check_echo_loop_back"
        
        try:
            telnet_session_list.add(self.telnet_s2e_connect())
        except XmosTelnetTestFailure:
            test_state = TEST_FAIL
            test_message = "Failed after "+count+" connections"
        else:
            for line_count in range(0,lines):
                write_char = ""
                for i in range(0,test_len):
                    b = random.randint(0,len(character_bank)-1)
                    write_char += character_bank[b]
            
                try:
                    telnet_session.sendline(write_char)
                    telnet_session.expect(write_char, timeout=5)
                except pexpect.TIMEOUT:
                    test_state = self.TEST_FAIL
                    test_message = "Did not get correct character response (timeout=5), test_len="+test_len+", lines="+lines+", current line="+line_count
        
        # close connection
        telnet_session.close()
        
        self.print_test_info(test_name, test_state, test_message)
        return test_state