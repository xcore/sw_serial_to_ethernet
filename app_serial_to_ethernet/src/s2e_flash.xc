#include "web_server_flash.h"
#include "web_server.h"

void s2e_flash(chanend c_flash, chanend c_flash_data,
               fl_SPIPorts &flash_ports)
{
#ifdef WEB_SERVER_USE_FLASH
  web_server_flash_init(flash_ports);

  while (1) {
    select {
      case web_server_flash(c_flash, flash_ports);
      case c_flash_data :>  int cmd:
        // Here we can handle commands to save/restore data from flash
        // It needs to be stored after the web data (i.e. after
        // WEB_SERVER_IMAGE_SIZE)
      break;
    }
  }
#endif
}
