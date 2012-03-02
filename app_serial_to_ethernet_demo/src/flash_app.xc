#include "flash_common.h"
#include "debug.h"

void flash_data_read(chanend cPersData, char dptr[], int index_page)
{
	char channel_data;
	int i = 0;
	cPersData <: FLASH_DATA_READ;
	cPersData <: index_page;

    for(i = 0; i < FLASH_SIZE_PAGE; i++)
    {
    	cPersData :> channel_data;
    	dptr[i] = channel_data;
    }

	//printint(i);
	//printstrln(" : Recieved end of page");
}
