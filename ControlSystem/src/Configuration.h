
// Choose between WPS or SSID/Pass
// #define WPS_MODE

// port and ip
#define HOST_IP_ADDR "192.168.1.116"
#define PORT_VIDEO 2001
#define PORT_COMMAND 2000


#define DRIVE_UART_TX_PIN 27
#define DRIVE_UART_RX_PIN 26

#define FPGA_UART_TX_PIN 17
#define FPGA_UART_RX_PIN 16


#define I2S_VIDEO_BCLK_PIN 5
#define I2S_VIDEO_WS_PIN 18
#define I2S_VIDEO_DATA_PIN 19
#define I2S_CLEAR_TO_SEND GPIO_NUM_21

// Task Priorities
#define DRIVE_ARDUINO_COMM_PRIORITY 3
#define FPGA_COMM_PRIORITY 3
#define TCP_PRIORITY 5
#define READ_VIDEO_FRAME_PRIORITY 7

// Delay timings
#define TCP_COMMAND_INTERVAL 1000
#define TCP_VIDEO_INTERVAL 1000
#define DRIVE_ARDUINO_COMM_INTERVAL 1500
#define FPGA_COMM_INTERVAL 1500