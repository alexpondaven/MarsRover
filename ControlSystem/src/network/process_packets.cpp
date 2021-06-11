#include "Configuration.h"
#include "ArduinoJson.h"
#include "queues.h"
#include "esp_log.h"
#include <string>

extern TaskHandle_t exploration_task;

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

  StaticJsonDocument<384> doc;
    
    
    JsonObject coords = doc.createNestedObject("position");

    JsonArray cls = doc.createNestedArray("colors");
    JsonArray ags = doc.createNestedArray("angle");
    JsonArray dts = doc.createNestedArray("distance");
    coords["X"] = rover_coord.x;
    coords["Y"] = rover_coord.y;
    
    int dir;
    int speed = 1;
    if (direction.left) {
        dir = 2;
      } else if (direction.right) {
        dir = 3;
      } else if (direction.forward) {
        dir = 0;
      } else if (direction.backward) {
        dir = 1;
      } else {
        speed = 0;
        dir = 0;
      }
    coords["direction"] = dir;
    coords["speed"] = speed;

    for (int i=0; i<5; i++) {
      if (obs.obstacles[i].distance < 0) {
        cls[i] = -1;
      } else {
        cls[i] = i+1;
      }
      
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


extern "C" void recieve_TCP_packet(char * msg) {


    // ESP_LOGI("Recieve pkts", "Message is %s", msg);


    StaticJsonDocument<1024> recdoc;
    DeserializationError err = deserializeJson(recdoc, msg);
    if (err) {
      ESP_LOGE("Recieve TCP Packet", "Deserialisation Error %s with message %s",err.c_str(), msg);
    }
    int mode = recdoc["mode"];
    drive_tx_data_t drive_commands = {recdoc["direction"]["0"], recdoc["direction"]["1"], recdoc["direction"]["2"], recdoc["direction"]["3"]};
    rover_coord_t desired_position = {recdoc["position"]["0"], recdoc["position"]["1"]};
    ESP_LOGI("Recieve TCP Packet", "L: %d R: %d F: %d B: %d", drive_commands.left, drive_commands.right, drive_commands.forward, drive_commands.backward);

    hsv_t hsv_change;
    for (JsonObject elem : recdoc["videodetail"].as<JsonArray>()) {
      hsv_change.color = elem["color"];
      std::string s = elem["type"];
      hsv_change.type = s[0];
      hsv_change.option = elem["state"];
      hsv_change.value = (int) elem["value"];
      if (hsv_change.value == 10 ) {hsv_change.value = 11;} // make sure '\n' is not accidentally the value
      xQueueSendToFront(q_tcp_to_fpga, &hsv_change, 0);
    }

    xQueueOverwrite(q_tcp_to_drive, &drive_commands);
    xQueueOverwrite(q_tcp_to_explore, &desired_position);

    xTaskNotify(exploration_task, mode, eSetValueWithOverwrite);



}