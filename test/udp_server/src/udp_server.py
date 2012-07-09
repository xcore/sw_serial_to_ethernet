import socket
import time

#Ports for sendig and Listening
send_port = 15534
recv_port = 15533

ip = socket.gethostbyname(socket.gethostname())
Host_IP=str(ip)

print '\n'+'-------------------------------------------------------'
print '     WELCOME TO XMOS UDP BROADCAST SERVER FOR S2E      '
print '-------------------------------------------------------' + '\n'

print 'Your IP Address is :' +Host_IP +'\n'
option=raw_input( "Press 'y' to continue or 'n' to enter your IP address (y/n):")
option=str(option)
if( option == 'n'):
	Host_IP = raw_input('Enter Your IP Address : ') # IP from where python scripts are running
	Host_IP=str(Host_IP)

#print '\n' + 'Using Default Send Port : ' + str(send_port)
#print 'Using Default Receive Port : ' + str(recv_port)

print '\n\tEnter 1 for Sending S2E Broadcast Command \n'
print '\tEnter 2 for Modifying IP of S2E  \n'
print '\tEnter 3 for Modifying IP of S2E in Broadcast mode \n\t\t(Useful if invalid S2E IP needs to be modified)  \n'
print '\tPress any other key for exit \n'

action=raw_input()
action=str(action)
Dest_IP=0
while  ((action == '1') or (action == '2') or (action == '3')) :

    if (action == '1') :
        s = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for sending data
        s1 = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for Listening Data

        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket fro Broadcasting Hello Message
        sock.bind( ( '', 0 ) )
        sock.setsockopt( socket.SOL_SOCKET, socket.SO_BROADCAST, 1 )
        sock.sendto( 'XMOS S2E REPLY', ( '<broadcast>',  send_port ) )

        print 'Brodcasted command: XMOS S2E REPLY '
        try:
            s1.bind( ( Host_IP, recv_port ) )
            msg_ack = s1.recv( 150 )

            print '\n' + 'Received Acknowledgement : ' + msg_ack  + '\n'

            i = 0
            version	= '- '
            mac_addr	= '- '
            ip_addr	= '- '

            while(msg_ack[i]!= 'V'):
                i+=1;
                
            while msg_ack[ i ] != ';' :
                version = version + msg_ack[ i ]
                i+=1
            i=i+1

            while msg_ack[ i ] != ';' :
                mac_addr = mac_addr + msg_ack[ i ]
                i+=1
            i=i+1

            while  (i) != len(msg_ack) :
                ip_addr = ip_addr + msg_ack[ i ]
                i+=1
            k=0
            Dest_IP=ip_addr[2:len(ip_addr)]

            print '--------------S2E DETAILS----------------'
            print version
            print mac_addr
            print ip_addr
            print '------------------------------------------'

        except Exception, msg:
            print msg
            s1.close()
            s.close()
            exit( 1 )

        s1.close()
        s.close()

    elif (((action == '2') or (action == '3')) and (Dest_IP == 0)):
        print '\nDestination IP is Unknown. Choose option 1, instead\n'
        
    elif (action == '2'):
        s = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for sending data
        s1 = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for Listening Data

        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket fro Broadcasting Hello Message
        sock.bind( ( '', 0 ) )
        sock.setsockopt( socket.SOL_SOCKET, socket.SO_BROADCAST, 1 )

        ipaddress = raw_input('Input new IP adress : ' )
        try:
            s.sendto( "XMOS S2E IPCHANGE " + str( ipaddress ), ( Dest_IP, send_port ) )
            print "IP change in process..please wait"
            time.sleep(2)

        except :
            print '\nError in sending IP change request. Ip may be locked up. Try IP change in broadcast mode...\n'
            #s.sendto( "XMOS S2E IPCHANGE " + str( ipaddress ), ( '<broadcast>', send_port ) )
            s1.close()
            s.close()

        s1.close()
        s.close()

    elif (action == '3'):
        s = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for sending data
        s1 = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for Listening Data

        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket fro Broadcasting Hello Message
        sock.bind( ( '', 0 ) )
        sock.setsockopt( socket.SOL_SOCKET, socket.SO_BROADCAST, 1 )

        ipaddress = raw_input('Input new IP adress : ' )
        sock.sendto( "XMOS S2E IPCHANGE " + str( ipaddress ), ( '<broadcast>', send_port ) )
        print "IP change in process..please wait"
        time.sleep(2)

        s1.close()
        s.close()
        
    print '\n\n\n\tEnter 1 for Sending S2E Broadcast Command \n'
    print '\tEnter 2 for Modifying IP of S2E  \n'
    print '\tEnter 3 for Modifying IP of S2E in Broadcast mode \n\t\t(Useful if invalid S2E IP needs to be modified)  \n'
    print '\tPress any other key for exit \n'

    action=raw_input()
    action=str(action)
