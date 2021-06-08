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
   *      1
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
        ESP_LOGI("Drive UART", "x is %d, y is %d", rover_coord.x, rover_coord.y);

        // put data in q
        xQueueOverwrite(q_drive_to_tcp, &rover_coord);

      }
      int op;
      // recieve data from q
      xQueuePeek(q_tcp_to_drive, &drive_commands, portMAX_DELAY);

      // note: Size of json should be the same
      if (drive_commands.left) {
        op = 4;
      } else if (drive_commands.right) {
        op = 5;
      } else if (drive_commands.forward) {
        op = 1;
      } else if (drive_commands.backward) {
        op = 2;
      } else {
        op = 3;
      }

      req["opcode"] = op;
      serializeJson(req, reqbuff, reqlength);
      // send request by uart
      uart_write_bytes(UART_NUM_2, reqbuff, reqlength);

    vTaskDelay(DRIVE_ARDUINO_COMM_INTERVAL / portTICK_PERIOD_MS);
  }
}

void uart_fpga(void *params) {
  // Setup UART buffered IO with event queue
  QueueHandle_t uart_queue_fpga;
  // Enough space to queue 10 data structs
  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_1, 1024, 0, 10, &uart_queue_fpga, 0));

  
  char recievebuff[ (10*sizeof(bounding_box_t)) + 1 ]; // buffer for 10 boxes
  recievebuff[ (10*sizeof(bounding_box_t)) ] = 0; // null terminate

  uart_set_pin(UART_NUM_1, FPGA_UART_TX_PIN, FPGA_UART_RX_PIN, -1, -1);
  obstacles_t obstacles;
  
  while (1) {

      uart_flush(UART_NUM_1);
      uart_read_bytes(UART_NUM_1, (uint8_t *) &recievebuff, sizeof(recievebuff) - 1, portMAX_DELAY);

      char * msg = strtok(recievebuff, "\n");

      do {
        msg = strtok(NULL, "\n");
        bounding_box_t bbox = *((bounding_box_t *) msg);



        // skip zero bounding boxes
        obstacle_t obs;
        ESP_LOGI("FPGA UART", "BB: %c TL: (%d, %d) BR: (%d, %d)", bbox.color,bbox.topleft_x, bbox.topleft_y, bbox.bottomright_x, bbox.bottomright_y);
        if (bbox.bottomright_x || bbox.bottomright_y) {
          obs.bounding_box = bbox;
          uint32_t height = obs.bounding_box.bottomright_y - obs.bounding_box.topleft_y;
          uint32_t width = obs.bounding_box.bottomright_x - obs.bounding_box.topleft_x;
          uint32_t mid_x = obs.bounding_box.topleft_x + width;
          // uint32_t mid_y = obs.bounding_box.bottomright_y + height;

          //distance from camera values
    			   //ratio of sizes = ratio of distances - but inversely proportional
    			   // sx/sy=dy/dx  =>  dy = dx * sx /sy = 100 * 256 / sy
    			   // 0x100 or 256 pixels is 100 mm away
    			   // 0x80 is 200 mm
    			   //0x54 is 300 mm
    			obs.distance = 100 * 256 /width;

          // ping pong balls are 38 mm = bb_width pixels wide (1 pixel = bb_width/38 mm)
          float dist_from_centre_mm =  (float) ((mid_x - 320) * (float) width / 38);

          // obs.distance = sqrtf( ((mid_x - 320) * (mid_x - 320)) + (mid_y * mid_y) ); 
          obs.area = width * height;
          obs.angle = asinf(dist_from_centre_mm / obs.distance);
          if (mid_x < 320) {
            obs.angle = -obs.angle;
          }

        } // non zero bounding boxes
        else {
          obs.distance = -1;
        }
          
        switch (obs.bounding_box.color)
        {
        case 'R':
          obstacles.obstacles[0] = obs;
          break;

        case 'Y':
          obstacles.obstacles[1] = obs;
          break;

        case 'P':
          obstacles.obstacles[2] = obs;
          break;

        case 'B':
          obstacles.obstacles[3] = obs;
          break;

        case 'G':
          obstacles.obstacles[4] = obs;
          break;
        } // switch
        
        
      } while( strlen(msg) == sizeof(bounding_box_t));
      

      xQueueOverwrite(q_color_obstacles, &obstacles);
      

      


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

  xTaskCreate(uart_drive_arduino, "Drive Arduino UART", 4096, NULL, DRIVE_ARDUINO_COMM_PRIORITY, NULL);
  xTaskCreate(uart_fpga, "FPGA UART", 3072, NULL, FPGA_COMM_PRIORITY, NULL);
}
