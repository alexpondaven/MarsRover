


#include "Configuration.h"

#ifdef WIFI
  #include "network/network.h"
#endif

extern void uart_setup();
extern void init_i2s();

extern "C" void app_main() {

  
  #ifdef WIFI
    wifi_main();
    tcp_client_main();
  #endif
  uart_setup();
  init_i2s();
}