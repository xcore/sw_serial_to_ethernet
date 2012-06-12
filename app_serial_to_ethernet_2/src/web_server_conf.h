#define WEB_SERVER_USE_FLASH

#define WEB_SERVER_FLASH_DEVICES flash_devices

#define WEB_SERVER_NUM_FLASH_DEVICES 1

// prototypes of functions called by the dynamic evaluation in the webpages

int s2e_web_get_baud(char buf[], int app_state, int connection_state);
int s2e_web_get_parity_selected(char buf[], int app_state, int connection_state, int parity);
int s2e_web_get_stop_bits_selected(char buf[], int app_state, int connection_state, int sb);
int s2e_web_get_char_len(char buf[], int app_state, int connection_state);
int s2e_web_get_port(char buf[], int app_state, int connection_state);


int s2e_web_configure(char buf[], int app_state, int connection_state);
