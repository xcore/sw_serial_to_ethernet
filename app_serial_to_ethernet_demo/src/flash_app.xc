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
#include "flash_common.h"
#include "flash_app.h"
#include "debug.h"

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  flash_access
*
*  \param flash_operation: the operation to perform, see flash_common.h for #defines
*  \param data[]: array where data is got from / stored to
*  \param address: for rom_read: address is the page number
*           for config: it is the actual address (get address using get_config_address)
*  \param cPersData: channel to pass data from Core 0 (Flash port present in Core0)
*  see: flash_wrapper.xc: flash_data_access()
*
**/
int flash_access(char flash_operation, char data[], int address, chanend cPersData)
{
    int i, rtnval;

    switch(flash_operation)
    {
        case FLASH_ROM_READ:
        {
            cPersData <: FLASH_ROM_READ;
            cPersData <: address; // page number
            for(i = 0; i < FLASH_SIZE_PAGE; i++)
            {
                cPersData :> data[i];
            }
            break;
        }
        case FLASH_CONFIG_WRITE:
        {
            // Write
            cPersData <: FLASH_CONFIG_WRITE;
            cPersData <: address;

            for(i = 0; i < FLASH_SIZE_PAGE; i++)
            {
                cPersData <: data[i];
            }
            break;
        }
        case FLASH_CONFIG_READ:
        {
            // Read
            cPersData <: FLASH_CONFIG_READ;
            cPersData <: address;

            for(i = 0; i < FLASH_SIZE_PAGE; i++)
            {
                cPersData :> data[i];
            }
            break;
        }

        default: break;
    }

    return 0;
}

/** =========================================================================
*  get_config_address
*  \param last_rom_page: page number of the last fs file
*  \param last_rom_length: length of the last fs file
*  \param cPersData: channel to pass data from Core 0 (Flash port present in Core0)
*  see: flash_wrapper.xc: flash_data_access()
*
**/
int get_config_address(int last_rom_page, int last_rom_length, chanend cPersData)
{
    int address;
    cPersData <: FLASH_GET_CONFIG_ADDRESS;
    cPersData <: last_rom_page;
    cPersData <: last_rom_length;
    cPersData :> address;
    return address;
}

/*=========================================================================*/
