#ifndef __TELNET_H__
#define __TELNET_H__
#include <xccompat.h>

void init_telnet_parse_state(REFERENCE_PARAM(int,parse_state));

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
