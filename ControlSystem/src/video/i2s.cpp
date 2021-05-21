#include "../Configuration.h"

/* I2S Digital Microphone Recording Example
   This example code is in the Public Domain (or CC0 licensed, at your option.)
   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/
#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/i2s.h"
#include "driver/gpio.h"
#include "esp_system.h"
#include <math.h>
#include "esp_log.h"
#include <sys/unistd.h>
#include <sys/stat.h>
#include "esp_err.h"

static const char* TAG = "I2S frame read";

#define FRAME_SIZE_BYTES 460800
#define LINE_SIZE_BYTES 960
#define BUFFER_LINES_READ 40
#define READ_BUFFER_SIZE LINE_SIZE_BYTES * BUFFER_LINES_READ

char video_frame_buff[READ_BUFFER_SIZE];
static size_t total_bytes_read;
size_t bytes_read;

void get_frame_i2s(void* params) {

  while (1) {

    // reset bytes read
    total_bytes_read = 0;
    bytes_read = 0;
    // ESP_LOGI(TAG, "Pointer of buffer: %d", (uint32_t) video_frame_buff);
    
    // stop and read the whole buffer
    gpio_set_level(I2S_CLEAR_TO_SEND, 1);
    for (int i=0; i<(FRAME_SIZE_BYTES/(READ_BUFFER_SIZE)) ; i++ ) {
      // wait until half the buffer has data and read
      i2s_read(I2S_NUM_0, (void *) video_frame_buff, READ_BUFFER_SIZE, &bytes_read, portMAX_DELAY);
      gpio_set_level(I2S_CLEAR_TO_SEND, 0);
      total_bytes_read += bytes_read;
      ESP_LOGI(TAG, "Read %d bytes", bytes_read);
    }

    ESP_LOGI(TAG, "Read %d bytes", total_bytes_read);
    ESP_LOGI(TAG, "First 2 pixels: %x %x %x", video_frame_buff[0], video_frame_buff[1], video_frame_buff[2]);
    ESP_LOGI(TAG, "Last 2 pixels: %x %x %x", video_frame_buff[READ_BUFFER_SIZE-3], video_frame_buff[READ_BUFFER_SIZE-2], video_frame_buff[READ_BUFFER_SIZE-1]);
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}



void init_i2s(void)
{

    // set the apll clk pin: https://esp32.com/viewtopic.php?f=5&t=1585
    // PIN_FUNC_SELECT(PIN_CTRL, CLK_OUT2);
    // generate mclk on gpio3
    REG_WRITE(PIN_CTRL, 0b111100000000);

    // set RX pin (GPIO3) to CLK_OUT2 function. This pin should map to D0 on the FPGA
    PIN_FUNC_SELECT(PERIPHS_IO_MUX_U0RXD_U, FUNC_U0RXD_CLK_OUT2);
    
    gpio_set_direction(I2S_CLEAR_TO_SEND, GPIO_MODE_OUTPUT);
    gpio_set_level(I2S_CLEAR_TO_SEND, 0);

    i2s_config_t i2s_config = {};
        i2s_config.mode = (i2s_mode_t) (I2S_MODE_SLAVE | I2S_MODE_RX);
        i2s_config.sample_rate = 48000;
        i2s_config.bits_per_sample = I2S_BITS_PER_SAMPLE_24BIT;
        i2s_config.channel_format = I2S_CHANNEL_FMT_ALL_LEFT;
        i2s_config.communication_format = I2S_COMM_FORMAT_STAND_I2S;
        i2s_config.intr_alloc_flags = ESP_INTR_FLAG_LEVEL1;
        i2s_config.dma_buf_count = 80; // max value allowed is 128
        i2s_config.dma_buf_len = 320/2;
        i2s_config.use_apll = 1;
        i2s_config.fixed_mclk = 20e6;//48000 * 24 * 2 * 8;

    i2s_pin_config_t pin_config;
    pin_config.bck_io_num = I2S_VIDEO_BCLK_PIN;
    pin_config.ws_io_num = I2S_VIDEO_WS_PIN;
    pin_config.data_out_num = I2S_PIN_NO_CHANGE;
    pin_config.data_in_num = I2S_VIDEO_DATA_PIN;

    ESP_ERROR_CHECK(i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL));
    ESP_ERROR_CHECK(i2s_set_pin(I2S_NUM_0, &pin_config));
    // ESP_ERROR_CHECK(i2s_set_clk(I2S_NUM_1, CONFIG_EXAMPLE_AUDIO_SAMPLE_RATE, I2S_BITS_PER_SAMPLE_16BIT, I2S_CHANNEL_MONO));
    // video_frame_buff = heap_caps_malloc(READ_BUFFER_SIZE, MALLOC_CAP_8BIT);

    xTaskCreate(get_frame_i2s, "Read frame I2S", 2048, NULL, READ_VIDEO_FRAME_PRIORITY, NULL);


    
}



