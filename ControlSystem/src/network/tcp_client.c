

#include "../Configuration.h"
/* BSD Socket API Example
   This example code is in the Public Domain (or CC0 licensed, at your option.)
   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/
#include <string.h>
#include <sys/param.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_netif.h"

#include "lwip/err.h"
#include "lwip/sockets.h"

#include "packets.h"
#include "../video/bitmap.h"


static const char *TAGC = "tcp_command";
static const char *TAGV = "tcp_video";
static const char *payload = "Message from ESP32 ";
void update_drive_SPI_data(uint8_t left, uint8_t right, uint8_t forward, uint8_t backward);
void prepare_TCP_packet(tcp_send_pkt_t *pkt);
extern xSemaphoreHandle s_semph_get_ip_addrs;
extern xSemaphoreHandle mutex_video_frame_buffer;
extern bitmap_t bitmap;


static void tcp_command(void *pvParameters)
{
    // ESP_ERROR_CHECK(example_connect());
    ESP_LOGI(TAGC, "Waiting for IP(s)");

    // block indefinitely until ip address obtained
    xSemaphoreTake(s_semph_get_ip_addrs, portMAX_DELAY);
    xSemaphoreGive(s_semph_get_ip_addrs);
    char rx_buffer[128];
    char host_ip[] = HOST_IP_ADDR;
    int addr_family = 0;
    int ip_protocol = 0;

    while (1) {

        tcp_send_pkt_t tcp_send_pkt;

        struct sockaddr_in dest_addr;
        dest_addr.sin_addr.s_addr = inet_addr(host_ip);
        dest_addr.sin_family = AF_INET;
        dest_addr.sin_port = htons(PORT_COMMAND);
        addr_family = AF_INET;
        ip_protocol = IPPROTO_IP;

        int sock =  socket(addr_family, SOCK_STREAM, ip_protocol);
        if (sock < 0) {
            ESP_LOGE(TAGC, "Unable to create socket: errno %d", errno);
            break;
        }
        ESP_LOGI(TAGC, "Socket created, connecting to %s:%d", host_ip, PORT_COMMAND);

        int err;
        while (connect(sock, (struct sockaddr *)&dest_addr, sizeof(struct sockaddr_in6)) != 0) {
            ESP_LOGE(TAGC, "Socket unable to connect: errno %d. Will keep trying", errno);
            vTaskDelay(4000 / portTICK_PERIOD_MS);
            break;
        }
        ESP_LOGI(TAGC, "Successfully connected");


        while (1) {
            // prepare_TCP_packet(&tcp_send_pkt);
       
            ESP_LOGI(TAGC, "Sending TCP Packet");

            int err = send(sock, payload, strlen(payload), 0);
            if (err < 0) {
                ESP_LOGE(TAGC, "Error occurred during sending: errno %d", errno);
                break;
            }

            int len = recv(sock, rx_buffer, sizeof(rx_buffer) - 1, 0);
            // Error occurred during receiving
            if (len < 0) {
                ESP_LOGE(TAGC, "recv failed: errno %d", errno);
                break;
            }
            // Data received
            else {
                rx_buffer[len] = 0; // Null-terminate whatever we received and treat like a string
                ESP_LOGI(TAGC, "Received %d bytes from %s:", len, host_ip);
                motor_control_pkt_t *pkt = (motor_control_pkt_t *) rx_buffer;
                ESP_LOGI(TAGC, "Recieved data %d, %d, %d, %d", pkt->left, pkt->right, pkt->forward, pkt->backward);
                update_drive_SPI_data(pkt->left, pkt->right, pkt->forward, pkt->backward);
            }

            vTaskDelay(TCP_INTERVAL / portTICK_PERIOD_MS);
        }

        if (sock != -1) {
            ESP_LOGE(TAGC, "Shutting down socket and restarting...");
            shutdown(sock, 0);
            close(sock);
        }
    }
    vTaskDelete(NULL);
}


static void tcp_video_frame(void *pvParameters)
{
    // ESP_ERROR_CHECK(example_connect());
    ESP_LOGI(TAGV, "Waiting for IP(s)");

    // block indefinitely until ip address obtained
    xSemaphoreTake(s_semph_get_ip_addrs, portMAX_DELAY);
    xSemaphoreGive(s_semph_get_ip_addrs);
    char rx_buffer[128];
    char host_ip[] = HOST_IP_ADDR;
    int addr_family = 0;
    int ip_protocol = 0;

    while (1) {

        tcp_send_pkt_t tcp_send_pkt;

        struct sockaddr_in dest_addr;
        dest_addr.sin_addr.s_addr = inet_addr(host_ip);
        dest_addr.sin_family = AF_INET;
        dest_addr.sin_port = htons(PORT_VIDEO);
        addr_family = AF_INET;
        ip_protocol = IPPROTO_IP;

        int sock =  socket(addr_family, SOCK_STREAM, ip_protocol);
        if (sock < 0) {
            ESP_LOGE(TAGV, "Unable to create socket: errno %d", errno);
            break;
        }
        ESP_LOGI(TAGV, "Socket created, connecting to %s:%d", host_ip, PORT_VIDEO);

        int err;
        while (connect(sock, (struct sockaddr *)&dest_addr, sizeof(struct sockaddr_in6)) != 0) {
            ESP_LOGE(TAGV, "Socket unable to connect: errno %d. Will keep trying", errno);
            vTaskDelay(4000 / portTICK_PERIOD_MS);
            break;
        }
        ESP_LOGI(TAGV, "Successfully connected");

        while (1) {
            // prepare_TCP_packet(&tcp_send_pkt);

            xSemaphoreTake(mutex_video_frame_buffer, portMAX_DELAY);
            // find first non zero pixel and write to BMP header
            char * first_pixel = &bitmap.FRAME_BUFFER[0];
            while (!*first_pixel++) {}
            uint32_t offset = first_pixel - &bitmap.FRAME_BUFFER[0];
            for (int i=0; i<4; i++) {
              bitmap.BITMAPFILEHEADER[10+i] = (char) offset;
              offset >>= 8;
            }
      
            ESP_LOGI(TAGV, "Sending TCP Packet");

            int err = send(sock, &bitmap, sizeof(bitmap_t), 0);


            xSemaphoreGive(mutex_video_frame_buffer);
            if (err < 0) {
                ESP_LOGE(TAGV, "Error occurred during sending: errno %d", errno);
                break;
            }

            // no recieve

            vTaskDelay(TCP_INTERVAL / portTICK_PERIOD_MS);
        }

        if (sock != -1) {
            ESP_LOGE(TAGV, "Shutting down socket and restarting...");
            shutdown(sock, 0);
            close(sock);
        }
    }
    vTaskDelete(NULL);
}



void tcp_client_main(void)
{
    

    // these are done by wps.c
    // ESP_ERROR_CHECK(nvs_flash_init());
    // ESP_ERROR_CHECK(esp_netif_init());
    // ESP_ERROR_CHECK(esp_event_loop_create_default());

    /* This helper function configures Wi-Fi or Ethernet, as selected in menuconfig.
     * Read "Establishing Wi-Fi or Ethernet Connection" section in
     * examples/protocols/README.md for more information about this function.
     */
    


    xTaskCreate(tcp_command, "tcp_client", 4096, NULL, TCP_PRIORITY, NULL);
    xTaskCreate(tcp_video_frame, "tcp_client", 4096, NULL, TCP_PRIORITY, NULL);
}