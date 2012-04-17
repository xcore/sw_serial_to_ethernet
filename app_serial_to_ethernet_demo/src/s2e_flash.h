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
#ifndef S2E_FLASH_H_
#define S2E_FLASH_H_
#include "common.h"
/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
// required for calculation of config_address and other stuff
#define FLASH_SIZE_PAGE             256
#define WPAGE_NUM_FILES             2

// flash_operation defines
#define FLASH_ROM_READ              '@'
#define FLASH_CONFIG_WRITE          '~'
#define FLASH_CONFIG_READ           '!'
#define FLASH_GET_CONFIG_ADDRESS    '#'

// indicate if there is a config present in flash
#define FLASH_VALID_CONFIG_PRESENT  '$'

#define S2E_FLASH_ERROR             -1
#define S2E_FLASH_OK                0

/*---------------------------------------------------------------------------
ports and clocks
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
typedef struct
{
    char name[32];
    int  page;
    int  length;
}fsdata_t;

/*---------------------------------------------------------------------------
extern variables
---------------------------------------------------------------------------*/
extern fsdata_t fsdata[];

/*---------------------------------------------------------------------------
static variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
#ifndef FLASH_THREAD
int flash_get_config_address(int last_rom_page, int last_rom_length);

int flash_read_rom(int page, char data[]);

int flash_write_config(int address, char data[]);

int flash_read_config(int address, char data[]);
#else //FLASH_THREAD
void flash_data_access(chanend cPersData);

int flash_access(char flash_operation,
                 char data[],
                 int address,
                 chanend cPersData);

int get_config_address(int last_rom_page,
                       int last_rom_length,
                       chanend cPersData);
#endif //FLASH_THREAD

#endif /* S2E_FLASH_H_ */
/*=========================================================================*/
