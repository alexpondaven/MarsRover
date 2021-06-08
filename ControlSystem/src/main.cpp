


#include "Configuration.h"

#include "network/network.h"

extern void uart_setup();
extern void init_i2s();
extern void exploration_main();

extern "C" void app_main() {

  

  wifi_main();
  tcp_client_main();

  uart_setup();
  init_i2s();
  exploration_main();
}