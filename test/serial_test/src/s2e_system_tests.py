import progressBar
import serial
import telnet_tests
import serial_tests

class XmosSerialToEthernetSystemTests(XmosTelnetTest, XmosSerialTest):
    
    def __init__(self, prog_bar=0, log_file=None, address, port, serial_dev):
        self.port_id = serial_port
        self.address = address
        self.serial_dev = serial_dev
