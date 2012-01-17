// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include "uip_server.h"
#include "getmac.h"
#include "ethernet_server.h"
#include "telnetd.h"
#include "telnet_app.h"
#include "app_manager.h"
#include "debug.h"

static int active_conn = -1;
static int register_app_callback = 0;

/* This function needs to
 * identify Uart channel from the input data,
 * */
void telnetd_recv_line(chanend tcp_svr,
                       int id,
                       char line[],
                       int len)
{
#ifdef DEBUG_LEVEL_3
  //printstrln(line);
#endif //DEBUG_LEVEL_3
  telnetd_send_line(tcp_svr, id, line);
}

void telnetd_new_connection(chanend tcp_svr, int id)
{
  char welcome[][50] = {"Welcome to s2e telnet server!",
                        "(This server config acts as echo server...)"};
  for (int i=0;i<2;i++)
    telnetd_send_line(tcp_svr, id, welcome[i]);
  active_conn = id;
}

void telnetd_close_connection(xtcp_connection_t *conn)
{
	int i;
	active_conn = -1;

	for (i=0;i<UART_TX_CHAN_COUNT;i++)
	{
		if (uart_channel_config[i].conn_id == conn->id)
		{
			/* Update client state to inactive */
			uart_channel_config[i].is_active = FALSE;
			break;
		}
	}
	telnetd_free_state(conn);
}

// Listen on the telnet port
void telnetd_set_new_session(chanend tcp_svr, int telnet_port)
{
  // Listen on the telnet port
  xtcp_listen(tcp_svr, telnet_port, XTCP_PROTOCOL_TCP);

  if (0 == register_app_callback)
  {
	  /* Register application callback function */
	  register_callback(&fill_uart_channel_data);
	  register_app_callback = 1;
  }

}

void telnetd_connection_closed(chanend tcp_svr, int id)
{
  active_conn = -1;
}

int telnetd_send_client_data(chanend tcp_svr)
{
	int success = 0;
	int valid_data_to_send = 0;

	int channel_id=0; //uart channel index
	int read_index=0; //uart rx buffer index
	int conn_id = 0;
	int connection_state_index = 0;
	unsigned int buf_depth=0;  //uart rx buffer data depth
	char buffer[RX_CHANNEL_FIFO_LEN] = "";

	valid_data_to_send = get_uart_channel_data(&channel_id, &conn_id, &read_index, &buf_depth, buffer);

	if (1 == valid_data_to_send)
	{
		connection_state_index = fetch_connection_state_index(conn_id);

		if (-1 != connection_state_index)
		{
			success = telnetd_send(tcp_svr, connection_state_index, buffer);
			if (1 == success)
			{
				update_uart_rx_channel_state(&channel_id, &read_index, &buf_depth);
			}
		}
#ifdef DEBUG_LEVEL_2
		else
		{
			printstr("telnet send failed. Conn Id is ");printint(conn_id);
			printstr(" Connection_state_index is "); printintln(connection_state_index);
		}
#endif //DEBUG_LEVEL_2
	}

	return success;
}

