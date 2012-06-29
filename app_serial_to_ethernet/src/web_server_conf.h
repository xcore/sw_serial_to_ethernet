#define WEB_SERVER_USE_FLASH

#define WEB_SERVER_FLASH_DEVICES flash_devices

#define WEB_SERVER_NUM_FLASH_DEVICES 1

#define WEB_SERVER_POST_RENDER_FUNCTION s2e_post_render

#define WEB_SERVER_FLASH_THREAD 1

#define WEB_SERVER_NUM_CONNECTIONS 2

// prototypes of functions called by the dynamic evaluation in the webpages
void s2e_post_render(int app_state, int connection_state);
int s2e_web_get_port(char buf[], int app_state, int connection_state);
int s2e_web_configure(char buf[], int app_state, int connection_state);

int s2e_web_get_id_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int id);

int s2e_web_get_cl_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int cl);

int s2e_web_get_br_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int br);

int s2e_web_get_pc_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int parity);

int s2e_web_get_sb_selected(char buf[],
                            int app_state,
                            int connection_state,
                            int stop_bits);
