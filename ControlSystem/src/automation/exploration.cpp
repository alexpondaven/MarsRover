
#include "Configuration.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "queues.h"

TaskHandle_t exploration_task;

QueueHandle_t q_tcp_to_explore;

#define PI 3.1415926
#define AVOIDANCE_ANGLE_DEG 40
#define AVOIDANCE_ANGLE_RAD AVOIDANCE_ANGLE_DEG * PI/180
#define CENTRE_LINE_X 320
#define RIGHT_LINE_X (CENTRE_LINE_X*2)
#define CENTRE_LINE_Y 240

void exploration_function(void * params) {
  obstacles_t obs_list;
  uint32_t notification_val;

  while (1) {

    vTaskDelay( EXPLORATION_INTERVAL / portTICK_PERIOD_MS);

    // block until non zero value is obtained. Used as a more lightweight semaphore/queue
    xTaskNotifyWait(0, 0, &notification_val, portMAX_DELAY);

    if (notification_val == 0) {
      // just give directions
      continue;
    } else if (notification_val == 1) {
      // follow position

    } else {
      // exploration mode

    }

    // check each of the obstacles
    xQueuePeek(q_color_obstacles, &obs_list, 0);

    // worry about obstacles within 30 cm (300mm)
    // float min_angle = 90.0f;
    // float max_angle = -90.0f;
    // for (int i=0; i<5; i++) {
    //   obstacle_t obs = obs_list.obstacles[i];
    //   if ((obs.distance < 300) && (obs.distance > 0)) {
    //     min_angle = min_angle > obs.angle ? obs.angle : min_angle;
    //     max_angle = max_angle < obs.angle ? obs.angle : max_angle;
    //   }
    // }

    uint16_t min_x = RIGHT_LINE_X;
    uint16_t max_x = 0;
    for (int i=0; i<5; i++) {
      obstacle_t obs = obs_list.obstacles[i];
      if ((obs.distance > 0) && (obs.distance < 600)) {
        min_x = min_x > obs.bounding_box.topleft_x ? obs.bounding_box.topleft_x : min_x;
        max_x = max_x < obs.bounding_box.bottomright_x ? obs.bounding_box.bottomright_x : max_x;
      }
    }

    drive_tx_data_t direction;
    // {left, right, forward, backward}

    if (min_x < max_x) {
      if (min_x > (RIGHT_LINE_X - max_x)) {
        // go left
        direction = {1,0,0,0};

      } else {
        // go right
        direction = {0,1,0,0};

      }
    } else {
      // no obstacles, go straight ahead
      direction = {0,0,1,0};

    }

    xQueueOverwrite(q_tcp_to_drive, &direction);
    
  } // while (1)
}

void exploration_main() {
  q_tcp_to_explore = xQueueCreate(1, sizeof(rover_coord_t));
  xTaskCreate(exploration_function, "Exploration Mode", 2048, NULL, EXPLORATION_PRIORITY, &exploration_task);
}
