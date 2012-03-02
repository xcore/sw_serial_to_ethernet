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
#include "flash_common.h"

#include "debug.h"
#include <string.h>
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

/*---------------------------------------------------------------------------
implementation
---------------------------------------------------------------------------*/

/** =========================================================================
*  read_from_flash
*
*  \param
*
**/
int read_from_flash(char read_data[], int index_page)
{
    int i;

    for(i = 0; i < FLASH_SIZE_PAGE; i++)
    {
        read_data[i] = '\0';
    }

    /* Connect to the FLASH */
    if (0 != fl_connectToDevice(flash_ports, myFlashDevices, 5))
    {
        return 0;
    }

    /*Get the FLASH type*/
    switch (fl_getFlashType())
    {
        case 0 : break;
        case ATMEL_AT25FS010 : break;
        case ATMEL_AT25DF041A : break;
        case WINBOND_W25X10 : break;
        case WINBOND_W25X20 : break;
        case WINBOND_W25X40 : break;
        default : printstrln( "FLASH fitted : Unexpected!" ); return 0; break;
    }

    // Read from the data partition
    if ( 0 != fl_readDataPage(index_page, read_data) )
    {
        return 0;
    }

    // Disconnect from the flash
    if ( 0 != fl_disconnect() )
    {
        return 0;
    }

    return 1;
}

/** =========================================================================
*  flash_data_access
*
*  \param
*
**/
void flash_data_access(chanend cPersData)
{
	char channel_data;
	int i;
	int index_page;
	char flash_page_data[FLASH_SIZE_PAGE];

	while(1)
	{
		select
		{
			case cPersData :> channel_data :
			{
				if (FLASH_DATA_READ == channel_data)
				{
					cPersData :> index_page;
					read_from_flash(flash_page_data, index_page);

				    for(i = 0; i < FLASH_SIZE_PAGE; i++)
				    {
				    	cPersData <: flash_page_data[i];
				    }

					//printint(i);
					//printstrln(" : Reached end of page");
				}
			}
			break;
			default:
				break;
		}
	}
}

/*=========================================================================*/
