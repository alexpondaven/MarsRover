
#include "Configuration.h"

#ifdef WIFI
  #include "WiFi/wifi.h"
#endif


extern "C" void app_main() {

  #ifdef WIFI
    wifi_main();
  #endif

}