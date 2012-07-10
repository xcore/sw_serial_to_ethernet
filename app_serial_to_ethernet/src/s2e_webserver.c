#include "s2e_webserver.h"
#include "web_server.h"
#include "uart_handler.h"
#include "s2e_conf.h"
#include "s2e_def.h"
#include "itoa.h"
#include <stdlib.h>
#include <string.h>
#include "telnet_to_uart.h"
#include "s2e_validation.h"
#include "s2e_flash.h"

typedef struct app_state_t
{
    chanend c_uart_config;
    chanend c_xtcp;
    chanend c_flash;
} app_state_t;

static app_state_t app_state;

static char success_msg[] = "Ok";
static char error_msg[] = "Error";

static int pending_telnet_port_change_id = -1;
static int pending_telnet_port_change_port = -1;

static int output_msg(char buf[], const char msg[])
{
    strcpy(buf, msg);
    return strlen(msg);
}

static int get_int_param(const char param[], int connection_state, int *err)
{
    *err = 0;
    char *param_str = web_server_get_param(param, connection_state);

    if (!param_str || !(*param_str))
    {
        *err = 1;
        return 0;
    }

    return atoi(param_str);
}

static int get_id_param(int connection_state)
{
    char *id_str = web_server_get_param("id", connection_state);

    if (!id_str)
        return -1;

    int id = atoi(id_str);

    if (id < 0 || id >= NUM_UART_CHANNELS)
        return -1;
    return id;
}

int s2e_web_configure(char buf[], int app_state, int connection_state)
{
    int err;
    int val;
    uart_config_data_t data;
    int telnet_port;
    chanend c_uart_config = (chanend) ((app_state_t *) app_state)->c_uart_config;
    chanend c_flash_data = (chanend) ((app_state_t *) app_state)->c_flash;
    char *err_msg;
    char *web_form_req;
    int flash_result;

    if (!web_server_is_post(connection_state))
        return 0;

    web_form_req = web_server_get_param("form_action", connection_state);

    if (strcmp(web_form_req, "Set") == 0)
    {
        val = get_int_param("id", connection_state, &err);
        if (err)
            return output_msg(buf, s2e_validation_bad_channel_id);

        data.channel_id = val;

        // Received Set request from web page
        val = get_int_param("pc", connection_state, &err);
        if (err)
            return output_msg(buf, s2e_validation_bad_parity_msg);
        data.parity = val;

        val = get_int_param("sb", connection_state, &err);
        if (err)
            return output_msg(buf, s2e_validation_bad_stop_bits_msg);
        data.stop_bits = val;

        val = get_int_param("br", connection_state, &err);
        if (err)
            return output_msg(buf, s2e_validation_bad_baudrate_msg);
        data.baud = val;

        val = get_int_param("cl", connection_state, &err);
        if (err)
            return output_msg(buf, s2e_validation_bad_char_len_msg);
        data.char_len = val;

        val = get_int_param("tp", connection_state, &err);
        if (err)
            return output_msg(buf, s2e_validation_bad_telnet_port_msg);

        telnet_port = val;

        data.polarity = 0;

        err_msg = s2e_validate_uart_config(&data);

        if (err_msg)
            return output_msg(buf, err_msg);

        err_msg = s2e_validate_telnet_port(data.channel_id, telnet_port);

        if (err_msg)
            return output_msg(buf, err_msg);

        // Do the setting

        uart_config_data_t *config = uart_get_config(data.channel_id);
        *config = data;
        uart_set_config(c_uart_config, &data);

        // We have to delay the changing of the telnet port until after the
        // page is rendered so we can use the tcp channel
        pending_telnet_port_change_id = data.channel_id;
        pending_telnet_port_change_port = telnet_port;

        return output_msg(buf, success_msg);

    } // Set
    else if (strcmp(web_form_req, "Save") == 0)
    {
        // Received Save request from web page
        send_cmd_to_flash_thread(c_flash_data, UART_CONFIG, FLASH_CMD_SAVE);

        for(int i = 0; i < NUM_UART_CHANNELS; i++)
        {
            uart_config_data_t *data1 = uart_get_config(i);
            send_data_to_flash_thread(c_flash_data, data1);
        }

        flash_result = get_flash_access_result(c_flash_data);

        if (flash_result == S2E_FLASH_OK)
        {
            return output_msg(buf, success_msg);
        }
        else
        {
            return output_msg(buf, error_msg);
        }

    } // Save
    else
    {
        // invalid request
        return output_msg(buf, error_msg);
    }

    return 0;
}

void s2e_post_render(int app_state, int connection_state)
{
    chanend c_xtcp = (chanend) ((app_state_t *) app_state)->c_xtcp;
    if (pending_telnet_port_change_id != -1)
    {
        telnet_to_uart_set_port(c_xtcp,
                                pending_telnet_port_change_id,
                                pending_telnet_port_change_port);
        pending_telnet_port_change_id = -1;
    }
}

int s2e_web_get_port(char buf[], int app_state, int connection_state)
{
    int id = get_id_param(connection_state);
    if (id == -1)
        return 0;

    int len = itoa(telnet_to_uart_get_port(id), buf, 10, 0);
    return len;
}

int s2e_web_get_cl_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int cl)
{
    int id = get_id_param(connection_state);
    if (id == -1)
        return 0;

    uart_config_data_t *data = uart_get_config(id);
    if (data->char_len == cl)
    {
        char selstr[] = "selected";
        strcpy(buf, selstr);
        return strlen(selstr);
    }
    return 0;
}

int s2e_web_get_br_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int br)
{
    int id = get_id_param(connection_state);
    if (id == -1)
        return 0;

    uart_config_data_t *data = uart_get_config(id);
    if (data->baud == br)
    {
        char selstr[] = "selected";
        strcpy(buf, selstr);
        return strlen(selstr);
    }
    return 0;
}

int s2e_web_get_pc_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int parity)
{
    int id = get_id_param(connection_state);
    if (id == -1)
        return 0;

    uart_config_data_t *data = uart_get_config(id);
    if (data->parity == parity)
    {
        char selstr[] = "selected";
        strcpy(buf, selstr);
        return strlen(selstr);
    }
    return 0;
}

int s2e_web_get_sb_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int stop_bits)
{
    int id = get_id_param(connection_state);
    if (id == -1)
        return 0;

    uart_config_data_t *data = uart_get_config(id);
    if (data->stop_bits == stop_bits)
    {
        char selstr[] = "selected";
        strcpy(buf, selstr);
        return strlen(selstr);
    }
    return 0;
}

void s2e_webserver_init(chanend c_xtcp,
                        chanend c_flash,
                        chanend c_uart_config,
                        chanend c_flash_data)
{
    web_server_init(c_xtcp, c_flash, NULL);
    // Store off these channels to be used by the functions called whilst
    // rendering web pages
    app_state.c_uart_config = c_uart_config;
    app_state.c_flash = c_flash_data;
    app_state.c_xtcp = c_xtcp;

    web_server_set_app_state((int) &app_state);
}

void s2e_webserver_event_handler(chanend c_xtcp,
                                 chanend c_flash,
                                 chanend c_uart_config,
                                 REFERENCE_PARAM(xtcp_connection_t, conn))
{
    web_server_handle_event(c_xtcp, c_flash, conn);
}

