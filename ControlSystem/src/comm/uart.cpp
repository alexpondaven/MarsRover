#include "Configuration.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "esp_event.h"
#include "esp_log.h"
#include "driver/uart.h"
#include <string>
#include <string.h>

#include "ArduinoJson.h"
#include "queues.h"
#include <cmath>
#include "limits.h"

QueueHandle_t q_drive_to_tcp;
QueueHandle_t q_tcp_to_drive;
QueueHandle_t q_color_obstacles;
QueueHandle_t q_tcp_to_fpga;
extern void process_bb(char * buff, size_t sizebuff);

void uart_drive_arduino(void *params) {

  
  // Setup UART buffered IO with event queue
  QueueHandle_t uart_queue_drive;
  // Enough space to queue 10 data structs
  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_2, 512, 512, 10, &uart_queue_drive, 0));
  uart_set_pin(UART_NUM_2, DRIVE_UART_TX_PIN, DRIVE_UART_RX_PIN, -1, -1);

  StaticJsonDocument<JSON_OBJECT_SIZE(2)> req;
  
  req["Type"] = "request";
  req["opcode"] = 3;
  int reqlength = measureJson(req);
  char reqbuff[reqlength];
  char recievebuff[100];
  serializeJson(req, reqbuff, reqlength);


  // first request
  uart_write_bytes(UART_NUM_2, reqbuff, reqlength);
  rover_coord_t rover_coord;
  drive_tx_data_t drive_commands;

  /**
   *      8
   *      |
   * 4 -  3  - 5
   *      |
   *      2
   * 
   * reset - 6
   * angle - 7
   */

  while (1) {

      // get size of rx buffer
      uint32_t length = 0;
      ESP_ERROR_CHECK(uart_get_buffered_data_len(UART_NUM_2, (size_t*)&length));
      if (length) {
        StaticJsonDocument<JSON_OBJECT_SIZE(4)> doc;
        
        uart_read_bytes(UART_NUM_2, (uint8_t *) &recievebuff, length, 100 / portTICK_PERIOD_MS);
        // ESP_LOGI("Drive_UART", "received %s", recievebuff);
        deserializeJson(doc, recievebuff);
        rover_coord.x = doc["X"];
        rover_coord.y = doc["Y"];
        // ESP_LOGI("Drive UART", "x is %d, y is %d", rover_coord.x, rover_coord.y);

        // put data in q
        xQueueOverwrite(q_drive_to_tcp, &rover_coord);

      }
      int op;
      // recieve data from q
      xQueuePeek(q_tcp_to_drive, &drive_commands, portMAX_DELAY);

      // note: Size of json should be the same
      if (drive_commands.left) {
        op = 5;
      } else if (drive_commands.right) {
        op = 4;
      } else if (drive_commands.forward) {
        op = 8;
      } else if (drive_commands.backward) {
        op = 2;
      } else {
        op = 3;
      }

      
      req["opcode"] = op;
      serializeJson(req, reqbuff, reqlength);
      // send request by uart
      // ESP_LOGI("Drive UART", "Sending %s", reqbuff);
      uart_write_bytes(UART_NUM_2, reqbuff, reqlength);

    vTaskDelay(DRIVE_ARDUINO_COMM_INTERVAL / portTICK_PERIOD_MS);
  }
}

void uart_fpga(void *params) {
  // Setup UART buffered IO with event queue
  QueueHandle_t uart_queue_fpga;
  // Enough space to queue 10 data structs
  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_1, 1024, 1024, 10, &uart_queue_fpga, 0));

  
  char recievebuff[ (10*sizeof(bounding_box_t)) + 1 ]; // buffer for 10 boxes
  recievebuff[ (10*sizeof(bounding_box_t)) ] = 0; // null terminate

  uart_set_pin(UART_NUM_1, FPGA_UART_TX_PIN, FPGA_UART_RX_PIN, -1, -1);
  
  struct send_hsv_t {
    char padding;
    hsv_t hsv_change;
   
  } send_hsv;
  struct send_hsv_t empty_hsv;
  empty_hsv.padding = '\n';
  empty_hsv.hsv_change.color = 0;
  empty_hsv.hsv_change.option = 0;
  empty_hsv.hsv_change.type = 0;
  empty_hsv.hsv_change.value = 0;
  send_hsv.padding = '\n';

  while (1) {

      while (xQueueReceive(q_tcp_to_fpga, &send_hsv.hsv_change, 0)) {
        // if ( (send_hsv.hsv_change.type == 'e') || (send_hsv.hsv_change.type == 'g') ) {
        //   for (int i=0; i<send_hsv.hsv_change.value; i++) {
        //     // ESP_LOGI("Drive UART", "Sending %s", (char *) &send_hsv);
        //     uart_write_bytes(UART_NUM_2, (char *) &send_hsv, sizeof(send_hsv_t));
        //   }
        // } else {
          ESP_LOGI("FPGA UART", "Sending %s", (char *) &send_hsv);
          uart_write_bytes(UART_NUM_2, (char *) &send_hsv, sizeof(send_hsv_t));
        // }
        
        
      } 
      // empty hsv
      uart_write_bytes(UART_NUM_2, (char *) &empty_hsv, sizeof(send_hsv_t));

      // uart_flush(UART_NUM_1);
      int sizeread = uart_read_bytes(UART_NUM_1, (uint8_t *) &recievebuff, sizeof(recievebuff) - 1, 20 / portTICK_PERIOD_MS);
      // ESP_LOGI("FPGA UART", "Read %d bytes %s", sizeread, recievebuff);

      process_bb(recievebuff, sizeread);

     
      
    vTaskDelay(FPGA_COMM_INTERVAL / portTICK_PERIOD_MS); // this is how long to delay for
  }
}

void uart_setup() {
  // power arduino
  const uart_port_t uart_num_fpga = UART_NUM_1;
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
  
  ESP_ERROR_CHECK(uart_set_pin(UART_NUM_1, FPGA_UART_TX_PIN, FPGA_UART_TX_PIN, -1, -1));
  

  // drive arduino
  const uart_port_t uart_num_drive = UART_NUM_2;
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
  
  ESP_ERROR_CHECK(uart_set_pin(UART_NUM_2, DRIVE_UART_TX_PIN, DRIVE_UART_RX_PIN, -1, -1));



  // create queue (mailbox) for drive data
  q_drive_to_tcp = xQueueCreate(1, sizeof(rover_coord_t));
  q_tcp_to_drive = xQueueCreate(1, sizeof(drive_tx_data_t));
  q_color_obstacles = xQueueCreate(1, sizeof(obstacles_t));

  q_tcp_to_fpga = xQueueCreate(20, sizeof(hsv_t));

  xTaskCreate(uart_drive_arduino, "Drive Arduino UART", 4096, NULL, DRIVE_ARDUINO_COMM_PRIORITY, NULL);
  xTaskCreate(uart_fpga, "FPGA UART", 3072, NULL, FPGA_COMM_PRIORITY, NULL);
}
