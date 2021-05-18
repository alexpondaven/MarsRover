#include <stdint.h>

typedef struct {
  uint8_t left, right, forward, backward;
} __attribute__((packed)) motor_control_pkt_t;