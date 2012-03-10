// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename:
Project :
Author  :
Version :
Purpose
-----------------------------------------------------------------------------


===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#include <platform.h>
#include <flashlib.h>
#include <flash.h>
#include <string.h>

#include "flash_common.h"
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/
on stdcore[0] : extern fl_SPIPorts flash_ports;

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/
// Array of allowed flash devices from "SpecMacros.h"
fl_DeviceSpec myFlashDevices[] =
{ FL_DEVICE_ATMEL_AT25FS010,
  FL_DEVICE_ATMEL_AT25DF041A,
  FL_DEVICE_WINBOND_W25X10,
  FL_DEVICE_WINBOND_W25X20,
  FL_DEVICE_WINBOND_W25X40};

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
int read_from_flash(int address, char data[]);
int write_to_flash(int address, char data[]);
int connect_flash();
int get_flash_config_address(int last_rom_page, int last_rom_length);
int get_flash_data_page_address(int data_page);

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  read_from_flash
*
*  \param address: address in flash to read data from
*  \param data: array where read data will be stored
*
**/
int read_from_flash(int address, char data[])
{
    if ( 0 != connect_flash()) { return -1; }
    // Read from the data partition
    if ( 0 != fl_readPage(address, data) ) { return -1; }
    // Disconnect from the flash
    if ( 0 != fl_disconnect() ) { return -1;}
    // return all ok
    return 0;
}

/** =========================================================================
*  Description
*
*  \param address: address in flash to write data to
*  \param data: array that will be written to flash
*
**/
int write_to_flash(int address, char data[])
{
    int address_copy = address;
    int ix_sector;
    int num_sectors;
    int sector;
    int current_sector_address;

    if ( 0 != connect_flash()) { return -1; }

    // find the sector where the address resides
    num_sectors = fl_getNumSectors();
    for(ix_sector = 0; ix_sector < num_sectors; ix_sector++)
    {
        current_sector_address = fl_getSectorAddress(ix_sector);

        if(current_sector_address == address)
        {
            sector = ix_sector;
            break;
        }
        else if(current_sector_address >= address)
        {
            sector = ix_sector - 1;
            break;
        }
    }

    // erase sector
    if (0 != fl_eraseSector(sector)) { return -1; }
    // write page
    if (0 != fl_writePage(address, data)) { return -1; }
    // disconnect
    if (0 != fl_disconnect()) { return -1; }
    // return all ok
    return 0;
}


/** =========================================================================
*  connect_flash
*
*  \param
*
**/
int connect_flash()
{
    /* Connect to the FLASH */
    if (0 != fl_connectToDevice(flash_ports, myFlashDevices, 5)) { return -1; }

    /*Get the FLASH type*/
    switch (fl_getFlashType())
    {
        case 0: break;
        case ATMEL_AT25FS010: break;
        case ATMEL_AT25DF041A: break;
        case WINBOND_W25X10: break;
        case WINBOND_W25X20: break;
        case WINBOND_W25X40: break;
        default: printstrln("FLASH fitted : Unexpected!"); return -1; break;
    }
    return 0; // all ok
}

/** =========================================================================
*  get_flash_config_address
*
*  \param last_rom_page: page number of the last fs file stored in data partition
*  \param last_rom_length: length of the last fs file stored in data partition
*
**/
int get_flash_config_address(int last_rom_page, int last_rom_length)
{
    int total_rom_bytes;
    int temp;
    int index_data_sector;
    int done = 0;
    int address = 0;

    if(0 != connect_flash()) { return -1; }

    // get number of bytes in ROM
    total_rom_bytes = last_rom_page + ((1 + last_rom_length) / FLASH_SIZE_PAGE);
    total_rom_bytes *= FLASH_SIZE_PAGE;

    // check if data partition is defined
    if(fl_getDataPartitionSize() == 0) { return -1; }

    // get the index of data sector
    index_data_sector = fl_getNumSectors() - fl_getNumDataSectors();

    // ROM resides in data partition.
    // Start of data partition + ROM size up-capped to sector
    while(done != 1)
    {
        temp = fl_getSectorSize(index_data_sector);
        if((total_rom_bytes - temp) <= 0)
        {
            done = 1;
        }
        else
        {
            total_rom_bytes -= temp;
        }

        if(index_data_sector < fl_getNumSectors())
        {
            index_data_sector++;
        }
        else
        {
            return -1;
        }
    } // while

    address = fl_getSectorAddress(index_data_sector);

    // disconnect
    if (0 != fl_disconnect()) { return -1; }

    return address;
}

/** =========================================================================
*  get_flash_data_page_address
*
*  \param data_page: page number
*
**/
int get_flash_data_page_address(int data_page)
{
    int address, index_data_sector;

    if(0 != connect_flash()) { return -1; }

    // get the index of data sector
    index_data_sector = fl_getNumSectors() - fl_getNumDataSectors();

    // address of the requested page is data_sector start address + page*page_size
    address = fl_getSectorAddress(index_data_sector) + (data_page * fl_getPageSize());

    return address;
}

/** =========================================================================
*  flash_data_access
*
*  \param cPersData: channel to pass data from Core 0 (Flash port present in Core0)
*
**/
void flash_data_access(chanend cPersData)
{
    char channel_data;
    int address, page, i, rom_page, rom_length;
    char flash_page_data[FLASH_SIZE_PAGE];

    while(1)
    {
        select
        {
            case cPersData :> channel_data :
            {
                if (FLASH_ROM_READ == channel_data)
                {
                    cPersData :> page;
                    // get page address
                    address = get_flash_data_page_address(page);
                    // read ROM
                    read_from_flash(address, flash_page_data);

                    for(i = 0; i < FLASH_SIZE_PAGE; i++)
                    {
                        cPersData <: flash_page_data[i];
                    }
                }
                else if(FLASH_CONFIG_WRITE == channel_data)
                {
                    cPersData :> address;
                    for(i = 0; i < FLASH_SIZE_PAGE; i++)
                    {
                        cPersData :> flash_page_data[i];
                    }
                    // write config
                    write_to_flash(address, flash_page_data);

                }
                else if(FLASH_CONFIG_READ == channel_data)
                {
                    cPersData :> address;
                    read_from_flash(address, flash_page_data);
                    for(i = 0; i < FLASH_SIZE_PAGE; i++)
                    {
                        cPersData <: flash_page_data[i];
                    }
                }
                else if(FLASH_GET_CONFIG_ADDRESS == channel_data)
                {
                    cPersData :> rom_page;
                    cPersData :> rom_length;
                    address = get_flash_config_address(rom_page, rom_length);
                    cPersData <: address;
                }
                break;
            } // case cPersData :> channel_data :
            default: break;
        } // select
    } // while(1)
}

/*=========================================================================*/
