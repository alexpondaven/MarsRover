#include <stdint.h>

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