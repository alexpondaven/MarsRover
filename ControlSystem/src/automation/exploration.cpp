
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

template <typename T> 
int sgn(T val) {
    return (T(0) < val) - (val < T(0));
};

void exploration_function(void * params) {
  obstacles_t obs_list;
  uint32_t notification_val;
  rover_coord_t desired_pos, old_pos, current_pos;

  while (1) {

    vTaskDelay( EXPLORATION_INTERVAL / portTICK_PERIOD_MS);

    // block until non zero value is obtained. Used as a more lightweight semaphore/queue
    xTaskNotifyWait(0, 0, &notification_val, portMAX_DELAY);

    if (notification_val == 0) {
      // just give directions
      continue;
    } 

    // check each of the obstacles
    xQueuePeek(q_color_obstacles, &obs_list, 0);

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

        // no obstacles
        if (notification_val == 1) { // position mode

          // get slope if moving forward
          old_pos = current_pos;
          xQueuePeek(q_drive_to_tcp, &current_pos, 0);
          xQueuePeek(q_tcp_to_explore, &desired_pos, 0);
          xQueuePeek(q_tcp_to_drive, &direction, 0);

          if (direction.forward) {
            rover_coord_t slope = {current_pos.x - old_pos.x , current_pos.y - old_pos.y};
            int32_t x_difference = desired_pos.x - current_pos.x;
            int32_t y_difference = desired_pos.y - current_pos.y;

            if ( (sgn(x_difference) == sgn(slope.x))   &&  (sgn(y_difference) == sgn(slope.y))  ) {
              // move forward, will move in correct x and y dir
              direction = {0,0,1,0};

            } else if ( (sgn(x_difference) != sgn(slope.x))   &&  (sgn(y_difference) != sgn(slope.y))  ) {
              // move backwards
              direction = {0,0,0,1};

            } else {
              // cannot determine whether left or right, just turn right
              direction = {0,1,0,0};
            }

            // if it were to travel in this direction, check multiplier of x and y to difference in direction
            // float mult_x = ((float) x_difference) / ((float) slope.x);
            // float mult_y = ((float) y_difference) / ((float) slope.y);

          } else {
            // not enough info, go straight ahead
            direction = {0,0,1,0};

          }
          

        } else { // exploration mode
            // no obstacles, go straight ahead
            direction = {0,0,1,0};
        }

      }


    
    

    



    

    xQueueOverwrite(q_tcp_to_drive, &direction);
    
  } // while (1)
}

void exploration_main() {
  q_tcp_to_explore = xQueueCreate(1, sizeof(rover_coord_t));
  xTaskCreate(exploration_function, "Exploration Mode", 2048, NULL, EXPLORATION_PRIORITY, &exploration_task);
}
