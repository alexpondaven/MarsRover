#include "../Configuration.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "esp_event.h"
#include "esp_log.h"
#include "driver/uart.h"

#include "power_motor_spi.h"

xSemaphoreHandle mutex_power_data;
power_rx_data_t power_rx_data;

xSemaphoreHandle mutex_drive_data;
drive_rx_data_t drive_rx_data;
drive_tx_data_t drive_tx_data;


void uart_power_arduino(void *params) {
  // Setup UART buffered IO with event queue
  QueueHandle_t uart_queue_power;
  // Enough space to recieve just 1 data struct
  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_2, 1024*2, 0, 10, &uart_queue_power, 0));

  while (1) {
    xSemaphoreTake(mutex_power_data, portMAX_DELAY); // delay until can access this

      uart_write_bytes(UART_NUM_2, (char*) &power_rx_data, sizeof(power_rx_data));

    xSemaphoreGive(mutex_power_data);

    vTaskDelay(POWER_ARDUINO_COMM_INTERVAL / portTICK_PERIOD_MS);
  }
}

void uart_drive_arduino(void *params) {
  // Setup UART buffered IO with event queue
  QueueHandle_t uart_queue_drive;
  // Enough space to queue 10 data structs
  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_1, 1024*2, 1024*2, 10, &uart_queue_drive, 0));

  while (1) {
    xSemaphoreTake(mutex_drive_data, portMAX_DELAY); // delay until can access this

      uart_write_bytes(UART_NUM_1, (char*) &drive_rx_data, sizeof(drive_rx_data));
      uint32_t length = 0;
      ESP_ERROR_CHECK(uart_get_buffered_data_len(UART_NUM_1, (size_t*)&length));
      for (int i=0; i < (length / sizeof(drive_rx_data)) ; i++) {
        uart_read_bytes(UART_NUM_1, (uint8_t *) &drive_rx_data, sizeof(drive_rx_data), 100 / portTICK_PERIOD_MS);
      }
      uart_flush(UART_NUM_1);

    xSemaphoreGive(mutex_drive_data);

    vTaskDelay(DRIVE_ARDUINO_COMM_INTERVAL / portTICK_PERIOD_MS);
  }
}

void uart_setup() {
  // power arduino
  const uart_port_t uart_num_power = UART_NUM_2;
  uart_config_t uart_config_power = {
      .baud_rate = 115200,
      .data_bits = UART_DATA_8_BITS,
      .parity = UART_PARITY_DISABLE,
      .stop_bits = UART_STOP_BITS_1,
      .flow_ctrl = UART_HW_FLOWCTRL_CTS_RTS,
      .rx_flow_ctrl_thresh = 122,
      .source_clk = UART_SCLK_APB,
  };
  // Configure UART parameters
  ESP_ERROR_CHECK(uart_param_config(uart_num_power, &uart_config_power));
  
  ESP_ERROR_CHECK(uart_set_pin(UART_NUM_2, POWER_UART_TX_PIN, POWER_UART_TX_PIN, POWER_UART_RTS_PIN, POWER_UART_CTS_PIN));
  

  // drive arduino
  const uart_port_t uart_num_drive = UART_NUM_1;
  uart_config_t uart_config_drive = {
      .baud_rate = 115200,
      .data_bits = UART_DATA_8_BITS,
      .parity = UART_PARITY_DISABLE,
      .stop_bits = UART_STOP_BITS_1,
      .flow_ctrl = UART_HW_FLOWCTRL_CTS_RTS,
      .rx_flow_ctrl_thresh = 122,
      .source_clk = UART_SCLK_APB,
  };
  // Configure UART parameters
  ESP_ERROR_CHECK(uart_param_config(uart_num_drive, &uart_config_drive));
  
  ESP_ERROR_CHECK(uart_set_pin(UART_NUM_1, DRIVE_UART_TX_PIN, DRIVE_UART_RX_PIN, DRIVE_UART_RTS_PIN, DRIVE_UART_CTS_PIN));
  // Setup UART buffered IO with event queue

  // Install UART driver using an event queue here
  // ESP_ERROR_CHECK(uart_driver_install(UART_NUM_2, 1024*2, 1024*2, 10, &uart_queue_drive, 0));

  mutex_drive_data = xSemaphoreCreateMutex();
  mutex_power_data = xSemaphoreCreateMutex();

  xTaskCreate(uart_drive_arduino, "Drive Arduino UART", 2048, NULL, DRIVE_ARDUINO_COMM_PRIORITY, NULL);
  xTaskCreate(uart_power_arduino, "Power Arduino UART", 2048, NULL, POWER_ARDUINO_COMM_PRIORITY, NULL);
}
