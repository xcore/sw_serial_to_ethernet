#ifndef __TELNET_H__
#define __TELNET_H__
#include <xccompat.h>

void init_telnet_parse_state(REFERENCE_PARAM(int,parse_state));

/**
 * This function implements Telnet server functionality. Mainly extracts
 * application data from XTCP data packets in telnet protocol format.
 * @param     data          Buffer to store application data filtered from
 *             telnet server
 * @param     len           Number of bytes of received data
 * @param     parse_state   Current state of telnet parser state machine
 * @param     close_request Flag to set when telnet client is suspended
 * @return              Length of application buffer
 */
int parse_telnet_buffer(char data[],
                        int len,
                        REFERENCE_PARAM(int, parse_state),
                        REFERENCE_PARAM(int, close_request));

int parse_telnet_bufferi(char data[],
                        int i,
                        int len,
                        REFERENCE_PARAM(int, parse_state),
                        REFERENCE_PARAM(int, close_request));


#endif // __TELNET_H__
