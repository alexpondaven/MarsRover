#include <stdint.h>
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/queue.h"

extern QueueHandle_t q_drive_to_tcp;
extern QueueHandle_t q_tcp_to_drive;
extern QueueHandle_t q_color_obstacles;
extern QueueHandle_t q_tcp_to_explore;
extern QueueHandle_t q_tcp_to_fpga;

typedef struct {
  int32_t x;
  int32_t y;
} __attribute__((packed)) rover_coord_t;


typedef struct {
  uint8_t left, right, forward, backward;
} drive_tx_data_t;

typedef struct {
  char color; // 0 to 5
  char type; //     'h'|'s'|'v'|               'e'|'g'
  char option; //  (true is max, false is min)|(true is add, false is minus)
  uint8_t value;

} hsv_t;

typedef struct {
  char pad1, pad2, color, pad3;
  uint16_t topleft_y;
  uint16_t topleft_x;
  uint16_t bottomright_y;
  uint16_t bottomright_x;
} bounding_box_t;

typedef struct {
  bounding_box_t bounding_box;
  float angle;
  float distance;
  uint32_t area;
  uint16_t mid_x, mid_y;
} obstacle_t;

typedef struct {
  obstacle_t obstacles[5];
} obstacles_t;