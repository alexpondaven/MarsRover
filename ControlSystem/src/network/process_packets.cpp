#include "Configuration.h"
#include "ArduinoJson.h"
#include "queues.h"
#include "esp_log.h"

extern "C" size_t prepare_TCP_packet(char * buff, size_t buffsize) {

  rover_coord_t rover_coord;
  obstacles_t obs;
  drive_tx_data_t direction;

  if (!xQueuePeek(q_drive_to_tcp, &rover_coord, 0)) {
    rover_coord.x = 0;
    rover_coord.y = 0;
  }

  if (!xQueuePeek(q_color_obstacles, &obs, 0)) {
    memset((void *) &obs, 0, sizeof(obs));
    obs.obstacles[0].distance = -1;
    obs.obstacles[1].distance = -1;
    obs.obstacles[2].distance = -1;
    obs.obstacles[3].distance = -1;
    obs.obstacles[4].distance = -1;
  }
  if (!xQueuePeek(q_tcp_to_drive, &direction, 0)) {
    memset((void *) &direction, 0, sizeof(direction));
  }

  StaticJsonDocument<192> doc;
    
    
    JsonObject coords = doc.createNestedObject("position");

    JsonArray cls = doc.createNestedArray("colors");
    JsonArray ags = doc.createNestedArray("angle");
    JsonArray dts = doc.createNestedArray("distance");
    coords["X"] = rover_coord.x;
    coords["Y"] = rover_coord.y;
    coords["speed"] = 1;
    int dir;
    if (direction.left) {
        dir = 4;
      } else if (direction.right) {
        dir = 5;
      } else if (direction.forward) {
        dir = 1;
      } else if (direction.backward) {
        dir = 2;
      } else {
        dir = 3;
      }
    coords["direction"] = dir;

    for (int i=0; i<5; i++) {
      cls[i] = i;
      ags[i] = obs.obstacles[i].angle;
      dts[i] = obs.obstacles[i].distance;
    }
    int sz;
    if (  (sz = measureJson(doc)) > buffsize) {
      ESP_LOGE("Process packets", "Serialised JSON is too large of size %d", sz);
    }
    // serializeJsonPretty(doc,s);
    return serializeJson(doc, buff, buffsize);

}

