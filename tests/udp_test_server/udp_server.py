import socket
import time

#Ports for sendig and Listening
send_port = 15534
recv_port = 15533

ip = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ip.connect(("google.com",80))
Host_IP = (ip.getsockname()[0])
ip.close()

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

action=raw_input('Enter Your Selection :')
action=str(action)
Dest_IP=0
ip_addr_arr =['0']
while  ((action == '1') or (action == '2') or (action == '3')) :

    if (action == '1') :
        flag_set=1
        ip_addr_arr =['0']
        s = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for sending data
        s1 = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for Listening Data

        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket fro Broadcasting Hello Message
        sock.bind( ( '', 0 ) )
        sock.setsockopt( socket.SOL_SOCKET, socket.SO_BROADCAST, 1 )
        sock.sendto( 'XMOS S2E REPLY', ( '<broadcast>',  send_port ) )

        print 'Brodcasted command: XMOS S2E REPLY '
        try:
            s1.bind( ( Host_IP, recv_port ) )
            variable=0
            STOP_RECEIVE =0
            while (STOP_RECEIVE == 0):
                    variable+=1
                    s1.settimeout(1)
                    try:
                            msg_ack = s1.recv(100)
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
                            ip_addr_arr.append(Dest_IP)

                            print '--------------S2E DETAILS----------------'
                            print version
                            print mac_addr[0]+' MAC:'+mac_addr[2:len(mac_addr)]
                            print ip_addr[0]+' IP:'+ip_addr[2:len(ip_addr)] 
                            print '------------------------------------------'

                    except socket.timeout:
                            STOP_RECEIVE =1
                            ip_addr_arr.append('END')
                            #print ip_addr_arr 

                        
            
        except Exception, msg:
            print msg
            s1.close()
            s.close()
            exit( 1 )

        s1.close()
        s.close()
    elif ((action == '2')  and (flag_set == 0)):
        print '\n"Select Option 1 before selecting any other options"\n'


    elif (((action == '2') ) and (Dest_IP == 0)):
        print '\n"Destination IP is Unknown. Choose option 1, instead"\n'
        
    elif (action == '2'):
        flag_set=0
        s = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for sending data
        s1 = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for Listening Data

        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket fro Broadcasting Hello Message
        sock.bind( ( '', 0 ) )
        sock.setsockopt( socket.SOL_SOCKET, socket.SO_BROADCAST, 1 )
        print ('\n\tList of Connected S2E Devices :')
        variable=1
        while(ip_addr_arr[variable] != 'END'):
                print '\n\t\t'+str(variable) +' : '+ip_addr_arr[variable]
                variable+=1
        variable1=int(raw_input('\nEnter to which S2E you want to change the IP :'))
        if(variable1 > 0 and variable1 < variable):
                Dest_IP=ip_addr_arr[variable1]
                print Dest_IP
                ipaddress = raw_input('Input new IP adress : ' )
                try:
                    s.sendto( "XMOS S2E IPCHANGE " + str( ipaddress ), ( Dest_IP, send_port ) )
                    print '"IP change in process..please wait..."'
                    time.sleep(6)

                except :
                    print '\nError in sending IP change request. Ip may be locked up. Try IP change in broadcast mode...\n'
                    #s.sendto( "XMOS S2E IPCHANGE " + str( ipaddress ), ( '<broadcast>', send_port ) )
                    s1.close()
                    s.close()
        else:
                print '\n\t"Select Valid IP Address to change.."'

        s1.close()
        s.close()

    elif (action == '3'):
        s = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for sending data
        s1 = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket for Listening Data

        sock = socket.socket( socket.AF_INET, socket.SOCK_DGRAM ) # Socket fro Broadcasting Hello Message
        sock.bind( ( '', 0 ) )
        sock.setsockopt( socket.SOL_SOCKET, socket.SO_BROADCAST, 1 )

        ipaddress = '0.0.0.0'
        sock.sendto( "XMOS S2E IPCHANGE " + str( ipaddress ), ( '<broadcast>', send_port ) )
        print "\nIP change in process..please wait"
        time.sleep(6)

        s1.close()
        s.close()
        
    print '\n\n\n\tEnter "1" for Sending S2E Broadcast Command \n'
    print '\tEnter "2" for Modifying IP of S2E  \n'
    print '\tEnter "3" for Modifying IP of S2E in Broadcast mode \n\t\t(Useful if invalid S2E IP needs to be modified)  \n'
    print '\tPress any other key for exit \n'

    action=raw_input('Enter Your Selection :')
    action=str(action)
