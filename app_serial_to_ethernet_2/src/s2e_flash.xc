#include "web_server_flash.h"
#include "web_server.h"

void s2e_flash(chanend c_flash, fl_SPIPorts &flash_ports)
{
#ifdef WEB_SERVER_USE_FLASH
  web_server_flash_init(flash_ports);

  while (1) {
    select {
      case web_server_flash(c_flash, flash_ports);
    }
  }
#endif
}
