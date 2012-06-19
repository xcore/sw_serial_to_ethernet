#ifndef _s2e_validation_h_
#define _s2e_validation_h_
#include "uart_handler.h"

extern char s2e_validation_bad_parity_msg[];
extern char s2e_validation_bad_baudrate_msg[];
extern char s2e_validation_bad_stop_bits_msg[];
extern char s2e_validation_bad_char_len_msg[];
extern char s2e_validation_bad_telnet_port_msg[];
extern char s2e_validation_bad_channel_id[];

#ifndef __XC__
char *s2e_validate_uart_config(uart_config_data_t *config);
char *s2e_validate_telnet_port(int channel_id, int p);
char *s2e_validate_channel_id(int channel_id);
#endif

#endif // _s2e_validation_h_
