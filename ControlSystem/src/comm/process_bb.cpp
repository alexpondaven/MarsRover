#include <vector>
#include <stdio.h>
#include "queues.h"
#include <string.h>
#include "esp_log.h"
#include <cmath>

#define byteswap(val) (##val >> 8) | ((##val & 0x00ff) << 8)


void process_bb(char * buff, size_t buffsize) {

  int idx = 0;
  obstacles_t obstacles;
  // Get first newline char and discard
  while (buff[idx++] != '\n') {}

  // ESP_LOGI("FPGA UART", "%s", buff);
  while ( (idx + sizeof(bounding_box_t)) < buffsize) {
    bounding_box_t bbox;
    obstacle_t obs;
    memcpy((void *) &bbox, (void *) (buff+idx), sizeof(bounding_box_t));
    
    bbox.bottomright_x = byteswap(bbox.bottomright_x);
    bbox.bottomright_y = byteswap(bbox.bottomright_y);
    bbox.topleft_x = byteswap(bbox.topleft_x);
    bbox.topleft_y = byteswap(bbox.topleft_y);
    idx += sizeof(bounding_box_t) + 1;

    


        ESP_LOGI("FPGA UART", "BB: %c TL: (%d, %d) BR: (%d, %d)", bbox.color, bbox.topleft_x,  bbox.topleft_y,  bbox.bottomright_x,  bbox.bottomright_y);
        if (bbox.bottomright_x || bbox.bottomright_y) {
          obs.bounding_box = bbox;
          uint32_t height = obs.bounding_box.bottomright_y - obs.bounding_box.topleft_y;
          uint32_t width = obs.bounding_box.bottomright_x - obs.bounding_box.topleft_x;
          uint32_t mid_x = obs.bounding_box.topleft_x + width;
          // uint32_t mid_y = obs.bounding_box.bottomright_y + height;

          //distance from camera values
    			   //ratio of sizes = ratio of distances - but inversely proportional
    			   // sx/sy=dy/dx  =>  dy = dx * sx /sy = 100 * 256 / sy
    			   // 0x100 or 256 pixels is 100 mm away
    			   // 0x80 is 200 mm
    			   //0x54 is 300 mm
    			obs.distance = 100 * 256 /width;

          // ping pong balls are 38 mm = bb_width pixels wide (1 pixel = bb_width/38 mm)
          float dist_from_centre_mm =  (float) ((mid_x - 320) * (float) width / 38);

          // obs.distance = sqrtf( ((mid_x - 320) * (mid_x - 320)) + (mid_y * mid_y) ); 
          obs.area = width * height;
          obs.angle = asinf(dist_from_centre_mm / obs.distance);
          if (mid_x < 320) {
            obs.angle = -obs.angle;
          }

        } // non zero bounding boxes
        else {
          obs.distance = -1;
        }
          
        switch (obs.bounding_box.color)
        {
        case 'R':
          obstacles.obstacles[0] = obs;
          break;

        case 'Y':
          obstacles.obstacles[1] = obs;
          break;

        case 'P':
          obstacles.obstacles[2] = obs;
          break;

        case 'B':
          obstacles.obstacles[3] = obs;
          break;

        case 'G':
          obstacles.obstacles[4] = obs;
          break;
        } // switch
  } 

      xQueueOverwrite(q_color_obstacles, &obstacles);
}