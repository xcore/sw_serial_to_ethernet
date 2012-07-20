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
/**
 *  s2e_flash
 *  The S2E flash thread will keep looking for data (or commands) on the 
 *  c_flash_data channel.
 *
 *  @param c_flash_web      channel for webpage data
 *  @param c_flash_data     channel for s2e data
 *  @param flash_ports      reference to flash ports used by the device
 *  @return none
 *
 **/
void s2e_flash(chanend c_flash_web,
               chanend c_flash_data,
               fl_SPIPorts &flash_ports);
#endif

/**
 *  send_cmd_to_flash_thread
 *  Send command to flash thread.
 *
 *  @param c_flash_data     channel for s2e data
 *  @param data_type        UART_CONFIG (or) IPVER
 *  @param command          FLASH_CMD_SAVE (or) FLASH_CMD_RESTORE
 *  @return none
 *
 **/
void send_cmd_to_flash_thread(chanend c_flash_data, 
                              int data_type, 
                              int command);

/**
 *  get_flash_access_result
 *  Get the flash access result after performing certain command.
 *
 *  @param c_flash_data     channel for s2e data
 *  @return int             S2E_FLASH_ERROR (or) S2E_FLASH_OK
 *
 **/
int get_flash_access_result(chanend c_flash_data);

/**
 *  send_data_to_flash_thread
 *  Send UART configuration data to flash. Send one configuration at a 
 *  time. In order to send configuration for all the channels, this routine 
 *  must be called in a loop; each time sending the current channels config.
 *
 *  @param c_flash_data     channel for s2e data
 *  @param data             reference to the current channel's config
 *  @return none
 *
 **/
void send_data_to_flash_thread(chanend c_flash_data,
                               REFERENCE_PARAM(uart_config_data_t, data));

/**
 *  get_data_from_flash_thread
 *  Get UART configuration data from flash. Get one configuration at a 
 *  time. In order to get configuration for all the channels, this routine must 
 *  be called in a loop; each time updating the current channels config. Telnet
 *  ports for each channel are also updated.
 *
 *  @param c_flash_data     channel for s2e data
 *  @param data             reference to the current channel's config to update
 *  @param telnet_port      reference to current channel's telnet port to update
 *  @return none
 *
 **/
void get_data_from_flash_thread(chanend c_flash_data,
                                REFERENCE_PARAM(uart_config_data_t, data),
                                REFERENCE_PARAM(int, telnet_port));

/**
 *  send_ipconfig_to_flash_thread
 *  Send IP configuration data to flash.
 *
 *  @param c_flash_data     channel for s2e data
 *  @param ip               reference to the current IP config
 *  @return none
 *
 **/
void send_ipconfig_to_flash_thread(chanend c_flash_data,
                                   REFERENCE_PARAM(xtcp_ipconfig_t, ip));

/**
 *  get_ipconfig_from_flash_thread
 *  Get IP configuration data from flash.
 *
 *  @param c_flash_data     channel for s2e data
 *  @param ip               reference to the current IP config
 *  @return none
 *
 **/
void get_ipconfig_from_flash_thread(chanend c_flash_data,
                                    REFERENCE_PARAM(xtcp_ipconfig_t, ip));


#endif // __s2e_flash_h__
