#include <stdint.h>

typedef struct {
  uint8_t left, right, forward, backward;
} __attribute__((packed)) motor_control_pkt_t;

typedef struct {
  uint16_t left_speed, right_speed;
  uint32_t battery_percent;
  uint32_t remaining_distance;
} __attribute__((packed)) tcp_send_pkt_t;