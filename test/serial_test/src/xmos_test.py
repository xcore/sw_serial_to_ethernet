import datetime
import progressBar
import sys

class XmosTestException(Exception):
    def __init__(self, msg):
        self.msg = msg
        
    def __str__(self):
        return self.msg
    
class XmosTest(object):
    
    TEST_FAIL=0
    TEST_PASS=1
    character_bank="1234567890-=qwetyuiop[]asdfghjkl;'#\\zxcvbnm,./ !\"$%^&*()_+QWERTYUIOP{}ASDFGHJKL:@~|ZXCVBNM<>?"
    
    test_state = None
    test_message = ""
    
    pb_enabled = 0
    log_file = None
    
    lf = sys.stdout
    
    def __init__(self, prog_bar=0, log_file=None):
        self.pb_enabled = prog_bar
        self.log_file = log_file
        
        if log_file is not None:
            lf = open(log_file, 'a')
    
    def setup_prog_bar(self, minValue = 0, maxValue = 10, totalWidth=12):
        if self.pb_enabled:
            self.pb_max_val = maxValue
            self.pb_min_val = minValue
            self.pb = progressBar.progressBar(minValue, maxValue , totalWidth)
        
    def update_prog_bar(self, value):
        if self.pb_enabled:
            self.pb.updateAmount(value)
            update_cond = int(self.pb_max_val/20)
            if update_cond == 0:
                update_cond = 1
            if ((value % update_cond == 0)):
                self.lf.write("\t"+str(self.pb)+"\r")
                self.lf.flush()
    
    def pb_print_start_test_info(self, test_name, target, message=None):
        """Print initial test message if utilising progress bar"""
        if self.pb_enabled:
            now = datetime.datetime.now()
            print >>self.lf, "["+now.strftime("%d-%m-%Y %H:%M")+"] Test: ",
            print >>self.lf, test_name,
            print >>self.lf, " Target: "+target
            if message is not None:
                print >>self.lf, "\tMessage: "+message

    def print_test_info(self, test_name, status, target=None, message=None):
        """Print standard end of test information"""
        now = datetime.datetime.now()
        
        print "["+now.strftime("%d-%m-%Y %H:%M")+"] Test: ",
        
        if status == self.TEST_FAIL:
            print >>self.lf, test_name,
            if target is not None:
                print >>self.lf, " Target: "+target,
            print >>self.lf, " Result: FAIL"
            if message is not None:
                print >>self.lf, "\tMessage: "+message
        if status == self.TEST_PASS:
            print >>self.lf, test_name+" Target: "+target+" Result: PASS"
            if message is not None:
                print >>self.lf, "\tMessage: "+message

    def print_to_log(self, test_name, message):
        if (self.log_file is not None):
            print >>self.lf, "["+now.strftime("%d-%m-%Y %H:%M")+"] Test: ",
            print >>self.lf, test_name,
            print >>self.lf, " Message: "+message
    
    def test_cleanup(self):
        if self.lf is not sys.stdout:
            self.lf.close()
            