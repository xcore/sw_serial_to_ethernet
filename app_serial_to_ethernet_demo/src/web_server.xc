// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*===========================================================================
 Filename: web_server.xc
 Project : app_serial_to_ethernet_demo
 Author  : XMOS Ltd
 Version : 1v0
 Purpose : This file implements web server functionality, handling application
 specific TCP/IP events, managing client data for communication
 -----------------------------------------------------------------------------

 ===========================================================================*/

/*---------------------------------------------------------------------------
 include files
 ---------------------------------------------------------------------------*/
#include <xs1.h>
#include "httpd.h"
#include "telnetd.h"
#include "xtcp_buffered_client.h"
#include "web_server.h"
#include "telnet_app.h"
#include "debug.h"
#include "s2e_flash.h"
#include "common.h"
#include "client_request.h"

#define ENABLE_XSCOPE 0

#if ENABLE_XSCOPE == 1
#include <print.h>
#include <xscope.h>
#endif
/*---------------------------------------------------------------------------
 constants
 ---------------------------------------------------------------------------*/
//#define PROCESS_USER_DATA_TMR_EVENT_INTRVL		(TIMER_FREQUENCY /	\
//										(MAX_BIT_RATE * UART_APP_TX_CHAN_COUNT))
#define PROCESS_USER_DATA_TMR_EVENT_INTRVL	3000 //500
/*---------------------------------------------------------------------------
 ports and clocks
 ---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
 typedefs
 ---------------------------------------------------------------------------*/
typedef enum
{
    TYPE_HTTP_PORT,
    TYPE_TELNET_PORT,
    TYPE_UNSUPP_PORT,
} AppPorts;

typedef enum
{
    TELNET_DATA,
    WEB_DATA,
    UDP_DATA,
    NIL_DATA_SOURCE,
} eUserDataSource;

/* Data structure to hold user client data */
typedef struct STRUCT_USER_DATA_FIFO
{
    unsigned int conn_local_port; //Local port_id of user data
    int conn_id; //Connection Identifier
    eUserDataSource data_source; //Who has provided this data?
    char user_data[TX_CHANNEL_FIFO_LEN]; // Data buffer
    int read_index; //Index of consumed data
    int write_index; //Input data to Tx api
    unsigned buf_depth; //depth of buffer to be consumed
}s_user_data_fifo;

/* Data structure to hold UART X data received from xtcp connections */
typedef struct STRUCT_XTCP_RECD_DATA_BUFFERS
{
    int uart_id;
    int conn_id;
    int read_index; //Index of consumed data
    int write_index; //Input data to Tx api
    int telnet_recd_data_index; //TODO: TBR
    unsigned buf_depth; //depth of buffer to be consumed
    char telnet_recd_data[XTCP_CLIENT_BUF_SIZE * 2];
    e_bool is_currently_serviced;
}s_xtcp_recd_data_fifo;

/* Data structure to hold UART X data received to send to xtcp connections */
typedef struct STRUCT_XTCP_SEND_DATA_BUFFERS
{
    int uart_id;
    int conn_id;
    unsigned buf_length;
    char uart_rx_buffer_to_send[RX_CHANNEL_FIFO_LEN];
}s_xtcp_send_data_fifo;

/* Data structure to map key uart config to app manager data structure */
typedef struct STRUCT_MAP_APP_MGR_TO_UART
{
    unsigned int uart_id; //UART identifier
    int conn_id; //Xtcp connection id
    int local_port; //User configured port e.g. (telnet)
}s_map_app_mgr_to_uart;

/*---------------------------------------------------------------------------
 global variables
 ---------------------------------------------------------------------------*/
s_user_data_fifo user_client_data_buffer;
s_map_app_mgr_to_uart user_port_to_uart_id_map[UART_APP_TX_CHAN_COUNT];
s_xtcp_recd_data_fifo xtcp_recd_data_buffer[UART_APP_TX_CHAN_COUNT];

/* Any time, a single MUART RX data is collected from MUART and sent to xtcp */
s_xtcp_send_data_fifo xtcp_send_data_buffer;

/*---------------------------------------------------------------------------
 static variables
 ---------------------------------------------------------------------------*/
int gPollForUartDataToFetchFromUartRx = 1;
int gPollForSendingUartDataToUartTx; //0 Initially reset this
int gPollForTelnetCommandData; //0 Initially reset this

int g_UartTxNumToSend;
char g_telnet_recd_data_buffer[XTCP_CLIENT_BUF_SIZE];
char g_telnet_actual_data_buffer[XTCP_CLIENT_BUF_SIZE];

/*---------------------------------------------------------------------------
 implementation
 ---------------------------------------------------------------------------*/

/** =========================================================================
 *  valid_telnet_port
 *
 *  checks whether port_num is a valid and configured telnet port
 *
 *  \param unsigned int	telnet port number
 *
 *  \return		1 		on success
 *
 **/
static int valid_telnet_port(unsigned int port_num)
{
    int i;
    /* Look up for configured telnet ports */
    for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
    {
        if (user_port_to_uart_id_map[i].local_port == port_num)
            return 1;
    }
    return 0;
}

/** =========================================================================
 *  fetch_conn_id_for_uart_id
 *
 *  Fetch conn_id that is active and mapped for user port
 *
 *  \param	int uart_id		UART Identifier
 *
 *  \return	None
 *
 **/
static int fetch_conn_id_for_uart_id(int uart_id)
{
    int i = 0;
    for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
    {
        if (user_port_to_uart_id_map[i].uart_id == uart_id)
        {
            return user_port_to_uart_id_map[i].conn_id;
        }
    }
    return -1;
}

/** =========================================================================
 *  fetch_uart_id_for_port_id
 *
 *  Fetch conn_id that is active and mapped for user port
 *
 *  \param	int local_port		XTCP Port number
 *
 *  \return	None
 *
 **/
static int fetch_uart_id_for_port_id(int local_port)
{
    int i;
    for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
    {
        if (user_port_to_uart_id_map[i].local_port == local_port)
        {
            return user_port_to_uart_id_map[i].uart_id;
        }
    }
    return -1;
}

/** =========================================================================
 *  update_user_conn_details
 *
 *  This function fetches data from user (telnet_ module and stores in a
 *  local buffer \, later to be sent to data manager through a channel
 *
 *  \param unsigned int	telnet_port : telnet client port number
 *
 *  \param unsigned int	conn_id : current active telnet client conn identifir
 *
 *  \return			None
 *
 **/
void update_user_conn_details(xtcp_connection_t &conn)
{
    int i;
    if (TELNET_PORT_USER_CMDS == conn.local_port)
    {
        user_client_data_buffer.buf_depth = 0;
        user_client_data_buffer.read_index = 0;
        user_client_data_buffer.write_index = 0;
        user_client_data_buffer.data_source = TELNET_DATA;
        user_client_data_buffer.conn_id = conn.id;
        user_client_data_buffer.conn_local_port = conn.local_port;
    }
    else
    {
        // Try and find UART X corresponding to conn
        for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
        {
            if (user_port_to_uart_id_map[i].local_port == conn.local_port)
            {
                user_port_to_uart_id_map[i].conn_id = conn.id;
                return;
            }
        }
    }
}

/** =========================================================================
 *  free_user_conn_details
 *
 *  This function fetches data from user (telnet_ module and stores in a
 *  local buffer \, later to be sent to data manager through a channel
 *
 *  \param unsigned int	telnet_port : telnet client port number
 *
 *  \param unsigned int	conn_id : current active telnet client conn identifir
 *
 *  \return			None
 *
 **/
void free_user_conn_details(xtcp_connection_t &conn)
{
    int i;
    if (TELNET_PORT_USER_CMDS == conn.local_port)
    {
        user_client_data_buffer.buf_depth = 0;
        user_client_data_buffer.read_index = 0;
        user_client_data_buffer.write_index = 0;
        user_client_data_buffer.data_source = NIL_DATA_SOURCE;
        user_client_data_buffer.conn_id = -1;
        user_client_data_buffer.conn_local_port = 0;
    }
    else
    {
        for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
        {
            if (user_port_to_uart_id_map[i].local_port == conn.local_port)
            {
                user_port_to_uart_id_map[i].conn_id = -1;
                return;
            }
        }
    }
}

/** =========================================================================
 *  fetch_user_data
 *
 *  This function fetches data from user (telnet_ module and stores in a
 *  local buffer, later to be sent to data manager through a channel
 *
 *  \param unsigned int	telnet_port : telnet client port number
 *
 *  \param unsigned int	conn_id : current active telnet client conn identifir
 *
 *  \return			None
 *
 **/
void fetch_user_data(xtcp_connection_t &conn, char data)
{
    int write_index = 0;
    if (TELNET_PORT_USER_CMDS == conn.local_port)
    {
        if (user_client_data_buffer.buf_depth < TX_CHANNEL_FIFO_LEN)
        {
            write_index = user_client_data_buffer.write_index;
            user_client_data_buffer.user_data[write_index] = data;
            write_index++;

            if (write_index >= TX_CHANNEL_FIFO_LEN)
            {
                write_index = 0;
            }
            user_client_data_buffer.write_index = write_index;
            user_client_data_buffer.buf_depth++;
        }
    }
}

static void app_buffers_init(void)
{
    int i;
    for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
    {
        xtcp_recd_data_buffer[i].uart_id = i;
        xtcp_recd_data_buffer[i].conn_id = -1;
        xtcp_recd_data_buffer[i].read_index = 0;
        xtcp_recd_data_buffer[i].write_index = 0;
        xtcp_recd_data_buffer[i].telnet_recd_data_index = 0;
        xtcp_recd_data_buffer[i].buf_depth = 0;
        xtcp_recd_data_buffer[i].telnet_recd_data[0] = '\0';
        if (i == (UART_APP_TX_CHAN_COUNT - 1))
        {
            /* Set last channel as currently serviced so that
             * channel queue scan order starts from first channel */
            xtcp_recd_data_buffer[i].is_currently_serviced = TRUE;
        }
        else
        {
            xtcp_recd_data_buffer[i].is_currently_serviced = FALSE;
        }
    }
    /* xtcp transmit buffer init */
    xtcp_send_data_buffer.buf_length = 0;
    xtcp_send_data_buffer.uart_id = -1;
    xtcp_send_data_buffer.conn_id = -1;
    xtcp_send_data_buffer.uart_rx_buffer_to_send[0] = '\0';
    /* Telnet command mode data buffer init  */
    user_client_data_buffer.buf_depth = 0;
    user_client_data_buffer.read_index = 0;
    user_client_data_buffer.write_index = 0;
    user_client_data_buffer.data_source = NIL_DATA_SOURCE;
    user_client_data_buffer.conn_id = -1;
    user_client_data_buffer.conn_local_port = 0;
}

/** =========================================================================
 *  modify_telnet_port
 *
 *  This function checks if UI has changed telnet port;
 *  Telnet port value is received from UART manager
 *  If there is a change, previous connection is closed and new conn is set up
 *
 *  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
 *
 *  \return			None
 *
 **/
static void modify_telnet_port(chanend tcp_svr, streaming chanend cWbSvr2AppMgr)
{
    int uart_id = 0;
    int telnet_port_num = 0;
    cWbSvr2AppMgr :> uart_id;
    cWbSvr2AppMgr :> telnet_port_num;
    if (user_port_to_uart_id_map[uart_id].local_port != telnet_port_num)
    {
        if (user_port_to_uart_id_map[uart_id].conn_id > 0) //Ensure a valid conn_id
        {
            xtcp_connection_t conn_release;
            /* Modify telnet sockets */
            conn_release.id = user_port_to_uart_id_map[uart_id].conn_id;
            conn_release.local_port = user_port_to_uart_id_map[uart_id].local_port;

            xtcp_unlisten(tcp_svr, conn_release.local_port);
            xtcp_abort(tcp_svr, conn_release);
        }
        /* Open a new telnet session */
        telnetd_set_new_session(tcp_svr, telnet_port_num);
        /* Update local port number */
        user_port_to_uart_id_map[uart_id].local_port = telnet_port_num;
    }
}

/** =========================================================================
 *  fetch_uart_data_and_send_to_client
 *
 *  This function performs the following:
 *  (i) Identifies which client to send to data
 *  (ii) Parses and sends uart data to appropriate user client
 *
 *  \param	chanend tcp_svr		channel end sharing uip_server thread
 *
 *  \return	None
 *
 **/
static void fetch_uart_data_and_send_to_client(chanend tcp_svr,
                                               xtcp_connection_t &conn,
                                               chanend cAppMgr2WbSvr)
{
    int i;
    int length_page;

    switch (conn.event)
    {
        case XTCP_RESEND_DATA:
        {
            xtcp_send(tcp_svr, xtcp_send_data_buffer.uart_rx_buffer_to_send, xtcp_send_data_buffer.buf_length);
            break;
        }
        case XTCP_REQUEST_DATA:
        {
            outct(cAppMgr2WbSvr, '2'); //PULL_UART_DATA_FROM_UART_TO_APP
            cAppMgr2WbSvr <: xtcp_send_data_buffer.uart_id;
            cAppMgr2WbSvr :> xtcp_send_data_buffer.buf_length;

            /* Get UART data */
            for (i=0; i<xtcp_send_data_buffer.buf_length; i++)
            {
                /* Store Uart X data from channel */
                cAppMgr2WbSvr :> xtcp_send_data_buffer.uart_rx_buffer_to_send[i];
            }

            xtcp_send(tcp_svr, xtcp_send_data_buffer.uart_rx_buffer_to_send, xtcp_send_data_buffer.buf_length);
            break;
        }
        case XTCP_SENT_DATA:
        {
            /* Check if there is more data to be sent to xtcp */
            xtcp_complete_send(tcp_svr);
            /* Enable poll to get other UART data */
            gPollForUartDataToFetchFromUartRx = 0;
            gPollForSendingUartDataToUartTx = 1;
            gPollForTelnetCommandData = 0;

            xtcp_send_data_buffer.buf_length = 0;
            xtcp_send_data_buffer.uart_id = -1;
            xtcp_send_data_buffer.conn_id = -1;
            xtcp_send_data_buffer.uart_rx_buffer_to_send[0] = '\0';
            break;
        } // case XTCP_SENT_DATA:
        default: break;
    } // switch(conn->event)
}

/** =========================================================================
 *  process_user_data
 *
 *  This function sends data collected into user buffers from user clients,
 *  to uart manager buffers through a channel
 *  (i) If telnet command data for UART configuration, data is send to UART
 *  manager after validation, and response is sent back to client
 *  (ii) If telnet data to UART X, data is directly sent to UART manager
 *
 *  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
 *
 *  \return			None
 *
 **/
#pragma unsafe arrays
#ifndef FLASH_THREAD
static void process_user_data(
                streaming chanend cWbSvr2AppMgr,
                chanend tcp_svr)
#else //FLASH_THREAD
static void process_user_data(streaming chanend cWbSvr2AppMgr,
                              chanend tcp_svr,
                              chanend cPersData)
#endif //FLASH_THREAD
{
    int read_index = 0;
    if ((user_client_data_buffer.buf_depth > 0) && (user_client_data_buffer.buf_depth <= TX_CHANNEL_FIFO_LEN))
    {
        /* Check if it is a UART command through telnet command socket */
        if (TELNET_PORT_USER_CMDS == user_client_data_buffer.conn_local_port)
        {
            char data[UI_COMMAND_LENGTH];
            char response[UI_COMMAND_LENGTH];
            int cmd_data_idx = 0;
            int cmd_complete = 0;
            unsigned buf_depth = 0;
            int connection_state_index = 0;

            /* UART Command available to service */
            /* If valid marker end is not present in command, ignore request till
             * a complete command is received */
            read_index = user_client_data_buffer.read_index;
            buf_depth = user_client_data_buffer.buf_depth;

            /* Send data continually */
            while ((buf_depth > 0) && (1 != cmd_complete))
            {
                data[cmd_data_idx]
                                = user_client_data_buffer.user_data[read_index];
                cmd_data_idx++;
                if (MARKER_END == user_client_data_buffer.user_data[read_index])
                {
                    cmd_complete = 1;
                    //break;
                }
                read_index++;

                if (read_index >= TX_CHANNEL_FIFO_LEN)
                {
                    read_index = 0;
                }
                buf_depth--;

                if ((0 == buf_depth) && (1 != cmd_complete))
                {
                    /* There is no valid command end marker - ignore the request*/
                    user_client_data_buffer.buf_depth = buf_depth;
                    user_client_data_buffer.read_index = read_index;
                }
            }
            if (1 == cmd_complete)
            {
                user_client_data_buffer.buf_depth = buf_depth;
                user_client_data_buffer.read_index = read_index;
                cmd_complete = 0;

                /* Parse commands and send to UART Manager via cWbSvr2AppMgr */
#ifndef FLASH_THREAD
                parse_client_request(cWbSvr2AppMgr,
                                data,
                                response,
                                cmd_data_idx);
#else //FLASH_THREAD
                parse_client_request(cWbSvr2AppMgr,
                                     cPersData,
                                     data,
                                     response,
                                     cmd_data_idx);
#endif //FLASH_THREAD
                /* Send response back to telnet client */
                connection_state_index
                                = fetch_connection_state_index(user_client_data_buffer.conn_id);
                telnetd_send_line(tcp_svr, connection_state_index, response);
            } //if (1 == cmd_complete)
        } //if (TELNET_PORT_USER_CMDS == user_client_data_buffer[i].conn_local_port)
    } //If there is any client data
}

/** =========================================================================
 *  web_server_handle_event
 *
 *  Uart manager event handler is a state machine to handle valid XTCP events,
 *  specific for HTTP and telnet clients
 *
 *  \param	chanend tcp_svr		channel end sharing uip_server thread
 *
 *  \param	xtcp_connection_t conn	reference to TCP client conn state mgt
 *  									structure
 *
 *  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
 *
 *  \return	None
 *
 **/
#pragma unsafe arrays
#ifndef FLASH_THREAD
void web_server_handle_event(
                chanend tcp_svr,
                xtcp_connection_t &conn,
                streaming chanend cWbSvr2AppMgr)
#else //FLASH_THREAD
void web_server_handle_event(chanend tcp_svr,
                             xtcp_connection_t &conn,
                             streaming chanend cWbSvr2AppMgr,
                             chanend cAppMgr2WbSvr,
                             chanend cPersData)
#endif //FLASH_THREAD
{
    AppPorts app_port_type = TYPE_UNSUPP_PORT;
    int WbSvr2AppMgr_chnl_data = 9999;
    int telnet_recd_data_len = 0;
    int uart_id = -1;

    // We have received an event from the TCP stack, so respond
    // appropriately
    // Ignore events that are not directly relevant to http and telnet
    switch (conn.event)
    {
        case XTCP_IFUP:
        case XTCP_IFDOWN:
        case XTCP_ALREADY_HANDLED: return;
        default: break;
    }

    // Check if the connection is a http or telnet connection
    if (HTTP_PORT == conn.local_port)
    {
        app_port_type=TYPE_HTTP_PORT;
    }
    else if ((valid_telnet_port(conn.local_port)) || (TELNET_PORT_USER_CMDS == conn.local_port))
    {
        app_port_type=TYPE_TELNET_PORT;
    }

    if ((app_port_type==TYPE_HTTP_PORT) || (app_port_type==TYPE_TELNET_PORT))
    {
        switch (conn.event)
        {
            case XTCP_NEW_CONNECTION:
            if (app_port_type==TYPE_HTTP_PORT)
            {
                httpd_init_state(tcp_svr, conn);
            }
            else if (app_port_type==TYPE_TELNET_PORT)
            {
                /* Initialize and manage telnet connection state and set tx buffers */
                telnetd_init_state(tcp_svr, conn);
                /* Note connection details so that data is manageable at server level */
                update_user_conn_details(conn);
            }
            break;
            case XTCP_RECV_DATA:
            if (app_port_type==TYPE_HTTP_PORT)
            {
#ifndef FLASH_THREAD
                httpd_recv(tcp_svr, conn, cWbSvr2AppMgr);
#else //FLASH_THREAD
                httpd_recv(tcp_svr, conn, cPersData, cWbSvr2AppMgr);
#endif //FLASH_THREAD
            }
            else if (TELNET_PORT_USER_CMDS == conn.local_port)
            {
                telnetd_recv(tcp_svr, conn);
            }
            else if (app_port_type==TYPE_TELNET_PORT)
            {
                /* Identify UART X associated with this connection */
                uart_id = fetch_uart_id_for_port_id(conn.local_port);
                if (-1 != uart_id)
                {
                    int TempLen = 0;
                    int i = 0;

                    TempLen = telnetd_recv_data(tcp_svr, conn, g_telnet_recd_data_buffer[0], g_telnet_actual_data_buffer[0]);
#if ENABLE_XSCOPE == 1
                    printstrln("***Current Pointers***");
                    printstr("Buffer Depth = "); printintln(xtcp_recd_data_buffer[uart_id].buf_depth);
                    printstr("TCP Data Length = "); printintln(TempLen);
                    printstrln("*****************************************************");
#endif
                    /*
                     * We receive the TCP data regardless of it being 'paused'.
                     * Ideally, the TCP should have stopped receiving data on a
                     * pause request. However, if a TCP packet comes in before
                     * a pause issue; this will be lost if we do not consume it.
                     *
                     * This is the reason why 'xtcp_recd_data_buffer[]' is of
                     * size (XTCP_CLIENT_BUF_SIZE * 2). So that, we can
                     * accommodate an extra (worst case) packet from TCP after
                     * the pause request.
                     *
                     * The reason why we place the below 'pause' threshold as
                     * (XTCP_CLIENT_BUF_SIZE/2) is not confidently known. We
                     * tried placing this threshold as XTCP_CLIENT_BUF_SIZE but
                     * that did not work (data loss). So, we assumed that there
                     * might be two packets arriving from the TCP after pause.
                     * So, we get the first packet and store it in our x2 buffer
                     * and by the time we get the second packet, we hope that
                     * the write / read pointers are beyond what will be
                     * over-written in the buffer. */

                    if (xtcp_recd_data_buffer[uart_id].buf_depth + TempLen >= XTCP_CLIENT_BUF_SIZE/2)
                    {
#if ENABLE_XSCOPE == 1
                        printstrln("!!!Pause!!!");
#endif
                        /* Pause the connection till buffer is consumed */
                        xtcp_pause(tcp_svr, conn);
                        /* Upon data consumption, unpause connection */
                    }

#if ENABLE_XSCOPE == 1
                        printstrln("***Updating buffers***");
                        printstr("Write pointer = "); printintln(xtcp_recd_data_buffer[uart_id].write_index);
                        printstr("TCP Data Length = "); printintln(TempLen);
#endif

                    for (i=0; i<TempLen; i++)
                    {
                        xtcp_recd_data_buffer[uart_id].telnet_recd_data[xtcp_recd_data_buffer[uart_id].write_index] = g_telnet_actual_data_buffer[i];
                        xtcp_recd_data_buffer[uart_id].write_index++;
                        if (xtcp_recd_data_buffer[uart_id].write_index >= (XTCP_CLIENT_BUF_SIZE * 2))
                        {
                            xtcp_recd_data_buffer[uart_id].write_index = 0;
                        }
                        xtcp_recd_data_buffer[uart_id].buf_depth++;
                    }
                }
            }
            break;
            case XTCP_SENT_DATA:
            case XTCP_REQUEST_DATA:
            case XTCP_RESEND_DATA:
            if (app_port_type==TYPE_HTTP_PORT)
#ifndef FLASH_THREAD
            httpd_send(tcp_svr, conn);
#else //FLASH_THREAD
            httpd_send(tcp_svr, conn, cPersData);
#endif //FLASH_THREAD
            else if (TELNET_PORT_USER_CMDS == conn.local_port)
            {
                /* Telnet User Commands */
                telnet_buffered_send_handler(tcp_svr, conn);
            }
            else if (app_port_type==TYPE_TELNET_PORT)
            {
                if (conn.id == xtcp_send_data_buffer.conn_id)
                {
                    /* There is xtcp bandwidth to accept data */
                    fetch_uart_data_and_send_to_client(tcp_svr, conn, cAppMgr2WbSvr);
                }
                else
                telnet_buffered_send_handler(tcp_svr, conn);
            }
            break;
            case XTCP_TIMED_OUT:
            case XTCP_ABORTED:
            case XTCP_CLOSED:
            if (app_port_type==TYPE_HTTP_PORT)
            httpd_free_state(conn);
            else if (app_port_type==TYPE_TELNET_PORT)
            telnetd_free_state(conn);

            free_user_conn_details(conn);
            break;
            default: break;
        }
        conn.event = XTCP_ALREADY_HANDLED;
    }
    return;
}

static void send_uart_tx_data(chanend tcp_svr, chanend cAppMgr2WbSvr)
{
    int buf_depth_avialable = 0;
    int i;
    int uart_id = 0;
    int data_to_send = 0;

    uart_id = g_UartTxNumToSend;
    cAppMgr2WbSvr <: uart_id;
    cAppMgr2WbSvr :> buf_depth_avialable;
    data_to_send = (xtcp_recd_data_buffer[g_UartTxNumToSend].buf_depth > buf_depth_avialable) ? buf_depth_avialable : xtcp_recd_data_buffer[g_UartTxNumToSend].buf_depth;
    cAppMgr2WbSvr <: data_to_send; //Amount of bytes to send

#if ENABLE_XSCOPE == 1
        printstrln("***Updating buffers***");
        printstr("Read pointer = "); printintln(xtcp_recd_data_buffer[uart_id].read_index);
#endif
    /* Get UART data */
    for (i=0; i<data_to_send; i++)
    {
        /* Send Uart X data to MUART TX */
        cAppMgr2WbSvr <: xtcp_recd_data_buffer[g_UartTxNumToSend].telnet_recd_data[xtcp_recd_data_buffer[g_UartTxNumToSend].read_index];
        xtcp_recd_data_buffer[g_UartTxNumToSend].read_index++;
        if (xtcp_recd_data_buffer[g_UartTxNumToSend].read_index >= XTCP_CLIENT_BUF_SIZE * 2)
        {
            xtcp_recd_data_buffer[g_UartTxNumToSend].read_index = 0;
        }
        xtcp_recd_data_buffer[g_UartTxNumToSend].buf_depth--;
    }

#if ENABLE_XSCOPE == 1
    printstr("Buffer depth after read = "); printintln(xtcp_recd_data_buffer[g_UartTxNumToSend].buf_depth);
#endif

    if (xtcp_recd_data_buffer[g_UartTxNumToSend].buf_depth <= 0)
    {
        xtcp_connection_t conn;
        conn.id = fetch_conn_id_for_uart_id(uart_id);
        xtcp_unpause(tcp_svr, conn);
#if ENABLE_XSCOPE == 1
            printstrln("***Unpause***");
#endif
    }

    gPollForUartDataToFetchFromUartRx = 1;
    gPollForSendingUartDataToUartTx = 0;
    gPollForTelnetCommandData = 0;
    g_UartTxNumToSend = -1;
}

static void post_uart_tx_data(chanend tcp_svr, chanend cAppMgr2WbSvr)
{
    int i;
    int j;

    for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
    {
        if (TRUE == xtcp_recd_data_buffer[i].is_currently_serviced)
        {
            break;
        }
    }
    xtcp_recd_data_buffer[i].is_currently_serviced = FALSE;
    i++;
    if (i >= UART_APP_TX_CHAN_COUNT)
    {
        i = 0;
    }
    xtcp_recd_data_buffer[i].is_currently_serviced = TRUE;

    if (xtcp_recd_data_buffer[i].buf_depth > 0)
    {
        /* Send CT */
        outct(cAppMgr2WbSvr, 'A'); //UART_CONTROL_TOKEN
        g_UartTxNumToSend = i;
        send_uart_tx_data(tcp_svr, cAppMgr2WbSvr);
    }
    gPollForUartDataToFetchFromUartRx = 1;
    gPollForSendingUartDataToUartTx = 0;
    gPollForTelnetCommandData = 0;
}

static void request_xtcp_init(chanend tcp_svr, chanend cAppMgr2WbSvr)
{
    cAppMgr2WbSvr :> xtcp_send_data_buffer.uart_id;
    xtcp_send_data_buffer.conn_id = fetch_conn_id_for_uart_id(xtcp_send_data_buffer.uart_id);
    if (-1 == xtcp_send_data_buffer.conn_id)
    {
        /* No telnet connective active for UART */
        xtcp_send_data_buffer.uart_id = -1; //Deinit state
        xtcp_send_data_buffer.buf_length = 0;
        gPollForUartDataToFetchFromUartRx = 0;
        gPollForSendingUartDataToUartTx = 1;
        gPollForTelnetCommandData = 0;
    }
    else
    {
        xtcp_connection_t conn;
        conn.id = xtcp_send_data_buffer.conn_id;
        xtcp_init_send(tcp_svr, conn);
    }
}

/** =========================================================================
 *  web_server
 *
 *  Web server thread. This thread handles
 *  (i) TCP events meant for the application and sends to web server state m/c
 *  (ii) Periodically sends telnet data to telnet clients
 *
 *  \param	chanend tcp_svr		channel end sharing uip_server thread
 *
 *  \param	chanend cWbSvr2AppMgr channel end sharing app manager thread
 *
 *  \return	None
 *
 **/
#pragma unsafe arrays
#ifndef FLASH_THREAD
void web_server(
                chanend tcp_svr,
                streaming chanend cWbSvr2AppMgr,
                chanend cAppMgr2WbSvr)
#else //FLASH_THREAD
void web_server(chanend tcp_svr,
                streaming chanend cWbSvr2AppMgr,
                chanend cAppMgr2WbSvr,
                chanend cPersData)
#endif //FLASH_THREAD
{
    xtcp_connection_t conn;
    timer processUserDataTimer;
    unsigned processUserDataTS;

    int config_address, flash_index_page_config, flash_length_config, i;
    char flash_data[FLASH_SIZE_PAGE];
    char r_data[FLASH_SIZE_PAGE];
    int WbSvr2AppMgr_uart_data;
    unsigned int AppMgr2WbSvr_uart_data;
    unsigned char tok;
#if ENABLE_XSCOPE == 1
    xscope_register(0, 0, "", 0, "");
    xscope_config_io(XSCOPE_IO_BASIC);
#endif
    /* Initiate HTTP and telnet connection state management */
    httpd_init(tcp_svr);
    telnetd_init_conn(tcp_svr);
    app_buffers_init();

    /* Exchange configured client ports (telnet/udp) */
    /* For now, keep it simple to get values from uart app module *///TODO: to remove telnet from app_mgr
    for (i = 0; i < UART_APP_TX_CHAN_COUNT; i++)
    {
        /* Fetch uart key data to app server */
        cWbSvr2AppMgr :> user_port_to_uart_id_map[i].uart_id;
    }

    /* Telnet port for executing user commands */
    telnetd_set_new_session(tcp_svr, TELNET_PORT_USER_CMDS);
    processUserDataTimer :> processUserDataTS;
    processUserDataTS += PROCESS_USER_DATA_TMR_EVENT_INTRVL;
    // Get configuration from flash
    flash_data[0] = MARKER_START;
    flash_data[1] = CMD_CONFIG_RESTORE;
    flash_data[2] = MARKER_START;
    flash_data[3] = MARKER_END;
    // Browser is requesting data
#ifndef FLASH_THREAD
    parse_client_request(cWbSvr2AppMgr,
                    flash_data,
                    r_data,
                    FLASH_SIZE_PAGE);
#else //FLASH_THREAD
    parse_client_request(cWbSvr2AppMgr,
                    cPersData,
                    flash_data,
                    r_data,
                    FLASH_SIZE_PAGE);
#endif //FLASH_THREAD
    // Loop forever processing TCP events
    while(1)
    {
        select
        {
#pragma ordered
            case cWbSvr2AppMgr :> WbSvr2AppMgr_uart_data :
            {
                if (UART_CMD_MODIFY_TLNT_PORT_FROM_UART_TO_APP == WbSvr2AppMgr_uart_data)
                {
                    modify_telnet_port(tcp_svr, cWbSvr2AppMgr);
                }
                else if (UART_CMD_MODIFY_ALL_TLNT_PORTS_FROM_UART_TO_APP == WbSvr2AppMgr_uart_data)
                {
                    for (i=0;i<UART_APP_TX_CHAN_COUNT;i++)
                    {
                        modify_telnet_port(tcp_svr, cWbSvr2AppMgr);
                    }
                }
            }
            break;
            case inct_byref(cAppMgr2WbSvr, tok):
            {
                if ('3' == tok) //UART_DATA_READY_UART_TO_APP

                {
                    request_xtcp_init(tcp_svr, cAppMgr2WbSvr);
                }
                else if ('4' == tok) //NO_UART_DATA_READY

                {
                    gPollForUartDataToFetchFromUartRx = 0;
                    gPollForSendingUartDataToUartTx = 0;
                    gPollForTelnetCommandData = 1;
                }
            }
            break;
#ifndef FLASH_THREAD
            case xtcp_event(tcp_svr, conn):
            web_server_handle_event(tcp_svr, conn, cWbSvr2AppMgr, cAppMgr2WbSvr);
            break;
            case processUserDataTimer when timerafter (processUserDataTS) :> char _ :
            //Send user data to Uart App
            process_user_data(cWbSvr2AppMgr, tcp_svr);
            processUserDataTS += PROCESS_USER_DATA_TMR_EVENT_INTRVL;
            break;
#else //FLASH_THREAD
            case xtcp_event(tcp_svr, conn):
            web_server_handle_event(tcp_svr, conn, cWbSvr2AppMgr, cAppMgr2WbSvr, cPersData);
            break;
            case processUserDataTimer when timerafter (processUserDataTS) :> char _ :
            if (gPollForUartDataToFetchFromUartRx)
            {
                /* Send CT */
                outct(cAppMgr2WbSvr, '1');
                gPollForUartDataToFetchFromUartRx = 0;
            }
            //TODO: More processing loop optim to be done for better xtcp recv rate

            else if (gPollForSendingUartDataToUartTx)
            {
                /* Perform TX data transfer */
                post_uart_tx_data(tcp_svr, cAppMgr2WbSvr);
            }
            else if (gPollForTelnetCommandData)
            {
                gPollForTelnetCommandData = 0;
                process_user_data(cWbSvr2AppMgr, tcp_svr, cPersData);
                gPollForUartDataToFetchFromUartRx = 0;
                gPollForSendingUartDataToUartTx = 1;
            }
            processUserDataTS += PROCESS_USER_DATA_TMR_EVENT_INTRVL;
            break;
#endif //FLASH_THREAD
            default: break;
        }
    }
}

