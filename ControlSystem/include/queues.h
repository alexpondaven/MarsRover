#include <stdint.h>
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/queue.h"

extern QueueHandle_t q_drive_to_tcp;
extern QueueHandle_t q_tcp_to_drive;

typedef struct {
  float x;
  float y;
} rover_coord_t;

typedef struct {
  uint32_t battery_percent;
  uint32_t remaining_distance;
} power_rx_data_t;

typedef struct {
  uint16_t left_speed, right_speed;
} drive_rx_data_t;

typedef struct {
  uint8_t left, right, forward, backward;
} drive_tx_data_t;