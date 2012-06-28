#include <stdlib.h>
#include <string.h>
#include "udp_discovery.h"
#include "xtcp_client.h"
#include "xtcp_client_conf.h"
#include "itoa.h"
#include "s2e_flash.h"
#include "util.h"

typedef struct connection_state_t {
  int conn_id;
  int active;
  int send_resp;
  char *err;
} connection_state_t;

static connection_state_t udp_disc_state;
static char buf[UDP_RECV_BUF_SIZE];
//UDP Response Format :: "XMOS S2E VER:a.b.c;MAC:xx:xx:xx:xx:xx:xx;IP:xxx.xxx.xxx.xxx";
static char *g_FirmwareVer = S2E_FIRMWARE_VER;
static char *g_UdpQueryString = UDP_QUERY_S2E_IP;
static char *g_UdpCmdIpChange = UDP_CMD_IP_CHANGE;

static char *g_RespString = "XMOS S2E VER:;MAC%;IP@";
static char invalid_udp_request[] = "Invalid UDP Server request\n";

static xtcp_ipaddr_t broadcast_addr = {255,255,255,255};
xtcp_ipconfig_t g_ipconfig;
unsigned char g_mac_addr[6];


#define USE_STATIC_IP   0

xtcp_ipconfig_t ipconfig =
{
#if USE_STATIC_IP
   {  169, 254, 196, 178},
   {  255, 255, 0, 0},
   {  0, 0, 0, 0}
#else
   { 0, 0, 0, 0 },
   { 0, 0, 0, 0 },
   { 0, 0, 0, 0 }
#endif
};

#pragma unsafe arrays
static void parse_udp_buffer(chanend c_xtcp,
		                 chanend c_flash_data,
                         xtcp_connection_t *conn,
                         char *buf,
                         int len)
{
	if ('R' == buf[9]) {
		udp_disc_state.send_resp = 1;
		xtcp_init_send(c_xtcp, conn);
	}
	else if ('I' == buf[9]) {
	  int j = 18;
	  int k = 0;
	  for (int i=j;i<len;i++) {
		if (buf[i] == '.') {
			buf[i] = '\0';
			g_ipconfig.ipaddr[k] = (unsigned char) atoi(&buf[j]);
			j = i+1;
			k++;
		}
	  }

	  if (4 == k) {
        send_cmd_to_flash_thread(c_flash_data, IPVER, FLASH_CMD_SAVE);
        send_ipconfig_to_flash_thread(c_flash_data, &g_ipconfig);
        chip_soft_reset();
	  }
	}
	else {
	  udp_disc_state.err = invalid_udp_request;
	  xtcp_init_send(c_xtcp, conn);
	}
}

#pragma unsafe arrays
static void construct_udp_response(char *buf)
{
	int len = 0;

	memcpy(buf, g_RespString, 13);
	buf += 13;

	memcpy(buf, g_FirmwareVer, strlen(g_FirmwareVer));
	buf += strlen(g_FirmwareVer);
	*buf = ';';
	buf++;

	for (int i=0; i<6; i++) {
	  len = itoa((int)g_mac_addr[i], buf, 10, 0);

	  if (0 == len) {
		*buf = '0';
	  }
	  else {
		buf += len;
	  }
	  buf++;

	  if (5!=i)
		*buf = ':';
	  else
		*buf = ';';

	  buf++;
	}

	for (int i=0; i<4; i++) {
	  len = itoa((int)g_ipconfig.ipaddr[i], buf, 10, 0);
	  buf += len;

	  if (0 == len) {
		*buf = '0';
	  }
	  buf++;

	  if (3!=i) {
	    *buf = '.';
		buf++;
	  }
	  else {
	    *buf = '\0';
	  }
    }
}

void udp_discovery_init(chanend c_xtcp, chanend c_flash_data, xtcp_ipconfig_t *p_ipconfig)
{
    int flash_result;

	udp_disc_state.active = 0;
	udp_disc_state.conn_id = -1;

	send_cmd_to_flash_thread(c_flash_data, IPVER, FLASH_CMD_RESTORE);
	flash_result = get_flash_access_result(c_flash_data);
	if(flash_result == S2E_FLASH_OK)
	{
	    get_ipconfig_from_flash_thread(c_flash_data, p_ipconfig);
	}
	else
	  memcpy((char *)p_ipconfig, (char *)&ipconfig, sizeof(xtcp_ipconfig_t));

}

#pragma unsafe arrays
void udp_discovery_event_handler(chanend c_xtcp,
                              chanend c_flash_data,
                              xtcp_connection_t *conn)
{
	int len;
	switch (conn->event)
	    {
	    case XTCP_IFUP:
	    	xtcp_get_ipconfig(c_xtcp, &g_ipconfig);
	    	xtcp_get_mac_address(c_xtcp, g_mac_addr);
	        xtcp_connect(c_xtcp, OUTGOING_UDP_PORT, broadcast_addr, XTCP_PROTOCOL_UDP);
	    case XTCP_IFDOWN:
	    case XTCP_ALREADY_HANDLED:
	      return;
	    default:
	      break;
	    }

	  if (OUTGOING_UDP_PORT == conn->remote_port) {
		  switch (conn->event)
	      {
		  case XTCP_NEW_CONNECTION:
			if (XTCP_IPADDR_CMP(conn->remote_addr, broadcast_addr)) {
	  	        udp_disc_state.conn_id = conn->id;
	  	        udp_disc_state.active = 1;
	  	        xtcp_bind_local(c_xtcp, conn, INCOMING_UDP_PORT);
			}
	        break;
	      case XTCP_RECV_DATA:
	    	  //len = xtcp_recv(c_xtcp, buf);
	    	  len = xtcp_recv_count(c_xtcp, buf, UDP_RECV_BUF_SIZE);
	    	  buf[len] = '\0';
	          if (!udp_disc_state.active)
	            break;

	          parse_udp_buffer(c_xtcp, c_flash_data, conn, buf, len+1);

	        break;
	      case XTCP_REQUEST_DATA:
	      case XTCP_RESEND_DATA:
	          if (!udp_disc_state.active)
	            break;

	          if (udp_disc_state.send_resp) {
	            construct_udp_response(buf);
	            xtcp_send(c_xtcp, buf, strlen(buf));
	          }
	          else if (udp_disc_state.err) {
	            xtcp_send(c_xtcp, udp_disc_state.err, strlen(udp_disc_state.err));
	          }
	          else {
	            xtcp_complete_send(c_xtcp);
	          }

	    	  break;
	      case XTCP_SENT_DATA:
	          xtcp_complete_send(c_xtcp);
	          if (udp_disc_state.active) {
	        	udp_disc_state.send_resp = 0;
	        	udp_disc_state.err = NULL;
	          }
	    	  break;
	      case XTCP_CLOSED:
	      case XTCP_ABORTED:
	      case XTCP_TIMED_OUT:
	      default:
	        break;
	    }
	    conn->event = XTCP_ALREADY_HANDLED;
	  }
}
