
#include "Configuration.h"

#ifdef WIFI
  #include "network/network.h"
#endif


extern "C" void app_main() {

  #ifdef WIFI
    wifi_main();
    tcp_client_main();
  #endif

}