#include "../comm/power_motor_spi.h"
#include "packets.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_event.h"

extern power_rx_data_t power_rx_data;
extern drive_rx_data_t drive_rx_data;
extern drive_tx_data_t drive_tx_data;
extern xSemaphoreHandle mutex_drive_data;
extern xSemaphoreHandle mutex_power_data;
extern "C" void update_drive_SPI_data(uint8_t left, uint8_t right, uint8_t forward, uint8_t backward);
extern "C" void prepare_TCP_packet(tcp_send_pkt_t *pkt);

void update_drive_SPI_data(uint8_t left, uint8_t right, uint8_t forward, uint8_t backward) {
  if (xSemaphoreTake(mutex_drive_data, 500 / portTICK_PERIOD_MS)) {
    drive_tx_data.left = left;
    drive_tx_data.right = right;
    drive_tx_data.forward = forward;
    drive_tx_data.backward = backward;

    xSemaphoreGive(mutex_drive_data);
  }
}

void prepare_TCP_packet(tcp_send_pkt_t *pkt) {
  if (xSemaphoreTake(mutex_drive_data, 500 / portTICK_PERIOD_MS)) {
    pkt->left_speed = drive_rx_data.left_speed;
    pkt->right_speed = drive_rx_data.right_speed;


    xSemaphoreGive(mutex_drive_data);
  }

  if (xSemaphoreTake(mutex_power_data, 500 / portTICK_PERIOD_MS)) {
    pkt->battery_percent = power_rx_data.battery_percent;
    pkt->remaining_distance = power_rx_data.remaining_distance;


    xSemaphoreGive(mutex_power_data);
  }

}