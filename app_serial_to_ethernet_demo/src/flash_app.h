/*
 * flash_app.h
 *
 *  Created on: Mar 2, 2012
 *      Author: XMOS
 */

#ifndef FLASH_APP_H_
#define FLASH_APP_H_

void flash_data_read(chanend cPersData,
		REFERENCE_PARAM(char, dptr),
		int dlen);

#endif /* FLASH_APP_H_ */
