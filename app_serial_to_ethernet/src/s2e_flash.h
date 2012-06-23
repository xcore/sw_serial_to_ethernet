#ifndef __s2e_flash_h__
#define __s2e_flash_h__

#include <xccompat.h>
#include <flash.h>
#include "uart_config.h"
#include "xtcp_client.h"

// define flash error cases
#define S2E_FLASH_ERROR     -1
#define S2E_FLASH_OK        0

// Relative (to webpage image) Index sectors (-1) where the data is present
#define UART_CONFIG         0
#define IPVER               1

// define flash access commands
#define FLASH_CMD_SAVE      1
#define FLASH_CMD_RESTORE   2

// indicate that data present in flash
#define FLASH_DATA_PRESENT  '$'



#ifdef __XC__
void s2e_flash(chanend c_flash_web,
               chanend c_flash_data,
               fl_SPIPorts &flash_ports);
#endif

int get_flash_access_result(chanend c_flash_data);

void send_cmd_to_flash_thread(chanend c_flash_data, int data_type, int command);

void get_ipconfig_from_flash_thread(chanend c_flash_data,
                                    REFERENCE_PARAM(xtcp_ipconfig_t, ip));

void send_ipconfig_to_flash_thread(chanend c_flash_data,
                                   REFERENCE_PARAM(xtcp_ipconfig_t, ip));

void send_data_to_flash_thread(chanend c_flash_data,
                               REFERENCE_PARAM(uart_config_data_t, data));

void get_data_from_flash_thread(chanend c_flash_data,
                                REFERENCE_PARAM(uart_config_data_t, data),
                                REFERENCE_PARAM(int, telnet_port));

#endif // __s2e_flash_h__
