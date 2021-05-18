#include "../Configuration.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "esp_event.h"

#include "sdkconfig.h"
#include "esp_log.h"

#include "power_motor_spi.h"
/*
 This code demonstrates how to use the SPI master half duplex mode to read/write a AT932C46D EEPROM (8-bit mode).
*/




#define PIN_NUM_MISO POWER_SPI_MISO_PIN
#define PIN_NUM_MOSI POWER_SPI_MOSI_PIN
#define PIN_NUM_CLK  POWER_SPI_SCLK_PIN

#define PIN_NUM_CS   POWER_SPI_CS_PIN




static const char TAG[] = "main";
static xSemaphoreHandle mutexSPI2;


xSemaphoreHandle mutex_power_data;
power_rx_data_t power_rx_data;

void SPI2_setup(void)
{
    esp_err_t ret;

    ESP_LOGI(TAG, "Initializing bus SPI%d...", HSPI_HOST+1);
    spi_bus_config_t buscfg={};
        buscfg.miso_io_num = PIN_NUM_MISO;
        buscfg.mosi_io_num = PIN_NUM_MOSI;
        buscfg.sclk_io_num = PIN_NUM_CLK;
        buscfg.quadwp_io_num = -1;
        buscfg.quadhd_io_num = -1;
        buscfg.max_transfer_sz = 32;
  
    //Initialize the SPI bus
    ret = spi_bus_initialize(HSPI_HOST, &buscfg, 0);
    ESP_ERROR_CHECK(ret);

    mutexSPI2 = xSemaphoreCreateMutex();
}

void power_arduino_SPI(void *params) {
    // Add a device
    spi_device_handle_t power_arduino_h;
    spi_device_interface_config_t power_arduino_config = {};
      power_arduino_config.spics_io_num = POWER_SPI_CS_PIN;
      power_arduino_config.address_bits = 0;
      power_arduino_config.command_bits = 0;
      power_arduino_config.flags = 0;
      power_arduino_config.clock_speed_hz = 4*1000*1000; // 4MHz

    esp_err_t ret = spi_bus_add_device(HSPI_HOST, &power_arduino_config, &power_arduino_h);
    ESP_ERROR_CHECK(ret);

    mutex_power_data = xSemaphoreCreateMutex();
    spi_transaction_t power_SPI_transmit = {};
      power_SPI_transmit.flags = 0;
      power_SPI_transmit.rx_buffer = (void *) &power_rx_data;
      power_SPI_transmit.rxlength = 0;
      power_SPI_transmit.length = sizeof(power_rx_data) * 8;
      power_SPI_transmit.tx_buffer = NULL; // no transmit


    while (1) {
      if (xSemaphoreTake(mutexSPI2, 1000 / portTICK_PERIOD_MS)) {

        xSemaphoreTake(mutex_power_data, portMAX_DELAY); // delay until can access this


        xSemaphoreGive(mutex_power_data);
        xSemaphoreGive(mutexSPI2);
      }
    }

}
