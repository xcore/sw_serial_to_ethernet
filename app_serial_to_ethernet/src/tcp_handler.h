#ifndef __TCP_HANDLER_H__
#define __TCP_HANDLER_H__

#ifdef __XC__
void tcp_handler(chanend c_xtcp,
                 chanend c_uart_data,
                 chanend c_uart_config,
                 chanend ?c_flash_web,
                 chanend ?c_flash_data);
#endif

#endif // __TCP_HANDLER_H__

