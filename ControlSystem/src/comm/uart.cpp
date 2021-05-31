#include "../Configuration.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "esp_event.h"
#include "esp_log.h"
#include "driver/uart.h"

#include "power_motor_spi.h"
#include "ArduinoJson.h"

// xSemaphoreHandle mutex_power_data;
// power_rx_data_t power_rx_data;

xSemaphoreHandle mutex_drive_data;
drive_rx_data_t drive_rx_data;
drive_tx_data_t drive_tx_data;



//     xSemaphoreGive(mutex_power_data);

//     vTaskDelay(POWER_ARDUINO_COMM_INTERVAL / portTICK_PERIOD_MS);
//   }
// }

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

void uart_fpga(void *params) {
  // Setup UART buffered IO with event queue
  QueueHandle_t uart_queue_drive;
  // Enough space to queue 10 data structs
  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_2, 1024*2, 1024*2, 10, &uart_queue_drive, 0));

  StaticJsonDocument<JSON_OBJECT_SIZE(1)> req;
  
  req["Type"] = "request";
  int reqlength = measureJson(req);
  char reqbuff[reqlength];
  char recievebuff[100];
  serializeJson(req, reqbuff, reqlength);

  // first request
  uart_write_bytes(UART_NUM_2, reqbuff, reqlength);

  while (1) {

      
      
      

      // get size of rx buffer
      uint32_t length = 0;
      ESP_ERROR_CHECK(uart_get_buffered_data_len(UART_NUM_2, (size_t*)&length));
      if (!length) {
        StaticJsonDocument<JSON_OBJECT_SIZE(2)> doc;
        
        uart_read_bytes(UART_NUM_2, (uint8_t *) &recievebuff, length, 100 / portTICK_PERIOD_MS);
        deserializeJson(doc, recievebuff);
        float x = doc["X"];
        float y = doc["Y"];
        ESP_LOGI("FPGA UART", "x is %f, y is %f", x, y);
      }
      

      // send request by uart
      uart_write_bytes(UART_NUM_2, reqbuff, reqlength);

    vTaskDelay(FPGA_COMM_INTERVAL / portTICK_PERIOD_MS); // this is how long to delay for
  }
}

void uart_setup() {
  // power arduino
  const uart_port_t uart_num_fpga = UART_NUM_2;
  uart_config_t uart_config_fpga = {
      .baud_rate = 115200,
      .data_bits = UART_DATA_8_BITS,
      .parity = UART_PARITY_DISABLE,
      .stop_bits = UART_STOP_BITS_1,
      .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
      .rx_flow_ctrl_thresh = 122,
      .source_clk = UART_SCLK_APB,
  };
  // Configure UART parameters
  ESP_ERROR_CHECK(uart_param_config(uart_num_fpga, &uart_config_fpga));
  
  ESP_ERROR_CHECK(uart_set_pin(UART_NUM_2, FPGA_UART_TX_PIN, FPGA_UART_TX_PIN, -1, -1));
  

  // drive arduino
  const uart_port_t uart_num_drive = UART_NUM_1;
  uart_config_t uart_config_drive = {
      .baud_rate = 115200,
      .data_bits = UART_DATA_8_BITS,
      .parity = UART_PARITY_DISABLE,
      .stop_bits = UART_STOP_BITS_1,
      .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
      .rx_flow_ctrl_thresh = 122,
      .source_clk = UART_SCLK_APB,
  };
  // Configure UART parameters
  ESP_ERROR_CHECK(uart_param_config(uart_num_drive, &uart_config_drive));
  
  ESP_ERROR_CHECK(uart_set_pin(UART_NUM_1, DRIVE_UART_TX_PIN, DRIVE_UART_RX_PIN, -1, -1));
  // Setup UART buffered IO with event queue

  // Install UART driver using an event queue here
  // ESP_ERROR_CHECK(uart_driver_install(UART_NUM_2, 1024*2, 1024*2, 10, &uart_queue_drive, 0));

  mutex_drive_data = xSemaphoreCreateMutex();
  // mutex_power_data = xSemaphoreCreateMutex();

  xTaskCreate(uart_drive_arduino, "Drive Arduino UART", 2048, NULL, DRIVE_ARDUINO_COMM_PRIORITY, NULL);
  xTaskCreate(uart_fpga, "FPGA UART", 3072, NULL, FPGA_COMM_PRIORITY, NULL);
}
