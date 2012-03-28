import progressBar
import serial
import telnet_tests
import serial_tests

class XmosSerialToEthernetSystemTests(XmosTelnetTest,XmosSerialTest):
    
    def __init__(self, address, port, serial_port):
        self.port_id = serial_port
        self.address = address
        self.port = port
