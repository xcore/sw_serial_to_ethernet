
#include <platform.h>
#include <flashlib.h>
#include <flash.h>
#include <string.h>
#include <stdlib.h>
#include "s2e_flash.h"
#include "web_server_flash.h"
#include "web_server.h"
#include "uart_config.h"
#include "s2e_def.h"
#include "telnet_to_uart.h"
#include "copy_array.h"

static int flash_sector_config = 0;
static int flash_address_config = 0;
static int flash_sector_ipver = 0;
static int flash_address_ipver = 0;

/** =========================================================================
 *  connect_flash
 *
 *  \return int          S2E_FLASH_OK / S2E_FLASH_ERROR
 **/
static int connect_flash(fl_SPIPorts &flash_ports)
{
    // connect to flash
    if (0 != fl_connectToDevice(flash_ports, flash_devices, 1)) { return S2E_FLASH_ERROR; }

    // get flash type
    switch (fl_getFlashType())
    {
        case NUMONYX_M25P16: break;
        default: return S2E_FLASH_ERROR; break;
    }
    // all ok
    return S2E_FLASH_OK;
}

/** =========================================================================
 *  update_data_location_in_flash
 *  update the config , ipver sectors and addresses in flash
 *
 *  \return int          S2E_FLASH_OK / S2E_FLASH_ERROR
 **/
static int update_data_location_in_flash(fl_SPIPorts &flash_ports)
{
    int total_rom_bytes;
    int temp;
    int index_data_sector;
    int done = 0;

    // connect to flash
    if (S2E_FLASH_OK != connect_flash(flash_ports)) { return S2E_FLASH_ERROR; }

    // get number of bytes in ROM
    total_rom_bytes = WEB_SERVER_IMAGE_SIZE;

    // check if data partition is defined
    if (fl_getDataPartitionSize() == 0)     { return S2E_FLASH_ERROR; }

    // get the index of data sector
    index_data_sector = fl_getNumSectors() - fl_getNumDataSectors();

    // ROM resides in data partition.
    // Start of data partition + ROM size up-capped to sector
    while (done != 1)
    {
        temp = fl_getSectorSize(index_data_sector);

        // check if image is contained within a sector
        if ((total_rom_bytes - temp) <= 0) { done = 1; }
        else { total_rom_bytes -= temp; }

        // check if we haven't exceeded beyond available data sectors
        // if exceeded, we have no more space to write in flash
        if (index_data_sector < fl_getNumSectors()) { index_data_sector++; }
        else { return S2E_FLASH_ERROR; }

    } // while

    // assuming that the config data size will not exceed sector size
    flash_sector_config = index_data_sector + UART_CONFIG;
    flash_address_config = fl_getSectorAddress(flash_sector_config);
    flash_sector_ipver = index_data_sector + IPVER;
    flash_address_ipver = fl_getSectorAddress(flash_sector_ipver);

    // return all ok
    return S2E_FLASH_OK;
}

/** =========================================================================
 *  read_from_flash
 *
 *  \param int  address  address in flash to read data from
 *  \param char data     array where read data will be stored
 *  \return int          S2E_FLASH_OK / S2E_FLASH_ERROR
 **/
#pragma unsafe arrays
int read_from_flash(int data_type, char data[], fl_SPIPorts &flash_ports)
{
    int sector;
    int address = 0;

    if(data_type == UART_CONFIG)
    {
        sector = flash_sector_config;
        address = flash_address_config;
    }
    else if(data_type == IPVER)
    {
        sector = flash_sector_ipver;
        address = flash_address_ipver;
    }

    // connect to flash
    if (S2E_FLASH_OK != connect_flash(flash_ports)) { return S2E_FLASH_ERROR; }
    // Read from the data partition
    if (S2E_FLASH_OK != fl_readPage(address, data)) { return S2E_FLASH_ERROR; }
    // Disconnect from the flash
    if (S2E_FLASH_OK != fl_disconnect())            { return S2E_FLASH_ERROR; }
    // return all ok
    return S2E_FLASH_OK;
}

/** =========================================================================
 *  write_to_flash
 *
 *  \param int  address  address in flash to write data to
 *  \param char data     array that will be written to flash
 *  \return int          S2E_FLASH_OK / S2E_FLASH_ERROR
 *
 **/
#pragma unsafe arrays
int write_to_flash(int data_type, char data[], fl_SPIPorts &flash_ports)
{
    int sector;
    int address = 0;

    if(data_type == UART_CONFIG)
    {
        sector = flash_sector_config;
        address = flash_address_config;
    }
    else if(data_type == IPVER)
    {
        sector = flash_sector_ipver;
        address = flash_address_ipver;
    }

    // connect to flash
    if (S2E_FLASH_OK != connect_flash(flash_ports))  {return S2E_FLASH_ERROR;}
    // erase sector
    if (S2E_FLASH_OK != fl_eraseSector(sector))      {return S2E_FLASH_ERROR;}
    // write page
    if (S2E_FLASH_OK != fl_writePage(address, data)) {return S2E_FLASH_ERROR;}
    // disconnect
    if (S2E_FLASH_OK != fl_disconnect())             {return S2E_FLASH_ERROR;}
    // return all ok
    return S2E_FLASH_OK;
}

/** =========================================================================
 *  send_cmd_to_flash_thread
 *
 *
 **/
void send_cmd_to_flash_thread(chanend c_flash_data, int data_type, int command)
{
    c_flash_data <: command;
    c_flash_data <: data_type;
}

/** =========================================================================
 *  send_data_to_flash_thread
 *
 *
 **/
void send_data_to_flash_thread(chanend c_flash_data, uart_config_data_t &data)
{
    int tel_port;
    tel_port = telnet_to_uart_get_port(data.channel_id);
    c_flash_data <: data;
    c_flash_data <: tel_port;
}

/** =========================================================================
 *  get_data_from_flash_thread
 *
 *
 **/
void get_data_from_flash_thread(chanend c_flash_data, uart_config_data_t &data, int &telnet_port)
{
    c_flash_data :> data;
    c_flash_data :> telnet_port;
}

/** =========================================================================
 *  get_flash_access_result
 *
 *
 **/
int get_flash_access_result(chanend c_flash_data)
{
    int result;
    c_flash_data :> result;
    return result;
}

/** =========================================================================
 *  send_data_to_flash_thread
 *
 *
 **/
void send_ipconfig_to_flash_thread(chanend c_flash_data, xtcp_ipconfig_t &ip)
{
    c_flash_data <: ip;
}

/** =========================================================================
 *  get_ipconfig_from_flash_thread
 *
 *
 **/
void get_ipconfig_from_flash_thread(chanend c_flash_data, xtcp_ipconfig_t &ip)
{
    c_flash_data :> ip;
}

/** =========================================================================
 *  s2e_flash
 *
 *
 **/
void s2e_flash(chanend c_flash, chanend c_flash_data, fl_SPIPorts &flash_ports)
{
#ifdef WEB_SERVER_USE_FLASH
    web_server_flash_init(flash_ports);
    update_data_location_in_flash(flash_ports);

    while (1)
    {
        select
        {
            case web_server_flash(c_flash, flash_ports);
            {

            } // case web_server_flash(c_flash, flash_ports);

            case c_flash_data :> int cmd:
            {
                // Here we can handle commands to save/restore data from flash
                // It needs to be stored after the web data (i.e. after
                // WEB_SERVER_IMAGE_SIZE)

                char flash_data[250];
                int i, j, data_type;
                int flash_result;

                switch(cmd)
                {
                    /* =========================================
                     * Save
                     * =========================================*/
                    case FLASH_CMD_SAVE:
                    {
                        flash_data[0] = FLASH_DATA_PRESENT;
                        j = 1;

                        // get data type - requesting config / ipversion data
                        c_flash_data :> data_type;

                        if(data_type == UART_CONFIG)
                        {
                            // get configuration data for all 8 channels
                            for(i = 0; i < NUM_UART_CHANNELS; i++)
                            {
                                uart_config_data_t data_config;
                                int tel_port;

                                c_flash_data :> data_config;
                                c_flash_data :> tel_port;

                                // append data to flash_data array
                                j = copy_config_to_array(flash_data,  j,  data_config, tel_port);

                            } // for(i = 0; i < NUM_UART_CHANNELS; i++)

                        } // if(data_type == UART_CONFIG)

                        else if(data_type == IPVER)
                        {
                            // get the IP and version details
                            xtcp_ipconfig_t ipconf;

                            c_flash_data :> ipconf;

                            flash_data[1] = ipconf.ipaddr[0];
                            flash_data[2] = ipconf.ipaddr[1];
                            flash_data[3] = ipconf.ipaddr[2];
                            flash_data[4] = ipconf.ipaddr[3];

                            flash_data[5] = ipconf.netmask[0];
                            flash_data[6] = ipconf.netmask[1];
                            flash_data[7] = ipconf.netmask[2];
                            flash_data[8] = ipconf.netmask[3];

                            flash_data[9] = ipconf.gateway[0];
                            flash_data[10] = ipconf.gateway[1];
                            flash_data[11] = ipconf.gateway[2];
                            flash_data[12] = ipconf.gateway[3];

                        } // else if(data_type == IPVER)

                        // write flash_data to flash
                        flash_result = write_to_flash(data_type,
                                                      flash_data,
                                                      flash_ports);

                        // send flash access result (-1) is error
                        c_flash_data <: flash_result;

                        break;
                    } // case FLASH_CMD_SAVE:

                    /* =========================================
                     * Restore
                     * =========================================*/
                    case FLASH_CMD_RESTORE:
                    {
                        j = 1;
                        // get data type - CONFIG or IPVER
                        c_flash_data :> data_type;
                        // read from flash
                        flash_result = read_from_flash(data_type,
                                                       flash_data,
                                                       flash_ports);

                        // send flash result
                        if(flash_data[0] != FLASH_DATA_PRESENT)
                        {
                            flash_result = -1; // no saved config present, send error
                        }

                        c_flash_data <: flash_result;

                        if(S2E_FLASH_OK == flash_result)
                        {
                            if(data_type == UART_CONFIG)
                            {
                                for(i = 0; i < NUM_UART_CHANNELS; i++)
                                {
                                    uart_config_data_t data_config;
                                    int tel_port;

                                    // append data to flash_data array
                                    j = copy_config_from_array(flash_data, j, data_config, tel_port);

                                    // send to channel
                                    c_flash_data <: data_config;
                                    c_flash_data <: tel_port;
                                }
                            } // if(data_type == UART_CONFIG)

                            else if(data_type == IPVER)
                            {
                                xtcp_ipconfig_t ipconf;

                                ipconf.ipaddr[0] = flash_data[1];
                                ipconf.ipaddr[1] = flash_data[2];
                                ipconf.ipaddr[2] = flash_data[3];
                                ipconf.ipaddr[3] = flash_data[4];

                                ipconf.netmask[0] = flash_data[5];
                                ipconf.netmask[1] = flash_data[6];
                                ipconf.netmask[2] = flash_data[7];
                                ipconf.netmask[3] = flash_data[8];

                                ipconf.gateway[0] = flash_data[9];
                                ipconf.gateway[1] = flash_data[10];
                                ipconf.gateway[2] = flash_data[11];
                                ipconf.gateway[3] = flash_data[12];

                                c_flash_data <: ipconf;

                            } // else if(data_type == IPVER)

                        } // if(S2E_FLASH_OK == flash_result)

                        break;
                    } // case FLASH_CMD_RESTORE:

                    /* =========================================
                     * Default
                     * =========================================*/
                    default: break;

                } // switch(cmd)
                break;
            } // case c_flash_data :>  int cmd:
        } // select
    } // while (1)
#endif
}
