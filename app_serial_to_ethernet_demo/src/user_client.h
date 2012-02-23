// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
Filename: user_client.h
Project : app_serial_to_ethernet_demo
Author  : XMOS Ltd
Version : 1v0
Purpose : This file delcares data structures and interfaces to contain
data parsing logic from different client interfaces (web, telnet etc)
-----------------------------------------------------------------------------

===========================================================================*/

/*---------------------------------------------------------------------------
include files
---------------------------------------------------------------------------*/
#ifndef _user_client_h_
#define _user_client_h_

/*---------------------------------------------------------------------------
constants
---------------------------------------------------------------------------*/
/* Length of buffer to hold user command response */
#define TLNT_CMD_USR_RESP_BUF_LEN	300
/* User parameter for telnet command */
#define TLNT_CMD_CHAR_USR_PARAM_LEN	10
/*---------------------------------------------------------------------------
typedefs
---------------------------------------------------------------------------*/
/** Data structure to hold telnet command response */
typedef struct STRUCT_USER_CLIENT_CMD_RESPONSE
{
	unsigned int 		pending_user_cmd_response;
	char				user_param_char_1[TLNT_CMD_CHAR_USR_PARAM_LEN];
	char				user_param_char_2[TLNT_CMD_CHAR_USR_PARAM_LEN];
	int					user_param_int_1;
	int					user_param_int_2;
	char				user_resp_buffer[TLNT_CMD_USR_RESP_BUF_LEN];
} s_user_client_cmd_response;

/*---------------------------------------------------------------------------
extern variables
---------------------------------------------------------------------------*/
extern s_user_client_cmd_response	user_client_cmd_resp;
/*---------------------------------------------------------------------------
global variables
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
prototypes
---------------------------------------------------------------------------*/
void parse_client_usr_command(char data);

#endif // _user_client_h_
