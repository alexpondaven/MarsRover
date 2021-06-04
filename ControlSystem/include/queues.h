#include <stdint.h>
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/queue.h"

extern QueueHandle_t q_drive_to_tcp;
extern QueueHandle_t q_tcp_to_drive;
extern QueueHandle_t q_color_obstacles;

typedef struct {
  float x;
  float y;
} __attribute__((packed)) rover_coord_t;


typedef struct {
  uint8_t left, right, forward, backward;
} drive_tx_data_t;



typedef struct {
  char color[4];
  uint16_t topleft_x;
  uint16_t topleft_y;
  uint16_t bottomright_x;
  uint16_t bottomright_y;
} bounding_box_t;

typedef struct {
  bounding_box_t bounding_box;
  float angle;
  float distance;
  uint32_t area;
} obstacle_t;

typedef struct {
  obstacle_t red;
  obstacle_t yellow;
  obstacle_t pink;
  obstacle_t blue;
  obstacle_t green;
} obstacles_t;