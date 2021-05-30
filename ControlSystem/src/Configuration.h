
// Choose between WPS or SSID/Pass
// #define WPS_MODE

// port and ip
#define HOST_IP_ADDR "192.168.1.116"
#define TCP_PORT 2000

// SPI for communication with power and drive system
// #define POWER_SPI_MOSI_PIN 13 // Also drive
// #define POWER_SPI_MISO_PIN 12 // Also drive
// #define POWER_SPI_SCLK_PIN 14 // Also drive

// #define POWER_SPI_CS_PIN 26
// #define DRIVE_SPI_CS_PIN 27

#define POWER_UART_TX_PIN 32
#define POWER_UART_RX_PIN 33
#define POWER_UART_CTS_PIN 22
#define POWER_UART_RTS_PIN 23

#define DRIVE_UART_TX_PIN 25
#define DRIVE_UART_RX_PIN 26
#define DRIVE_UART_CTS_PIN 27
#define DRIVE_UART_RTS_PIN 14

#define I2S_VIDEO_BCLK_PIN 5
#define I2S_VIDEO_WS_PIN 18
#define I2S_VIDEO_DATA_PIN 19
#define I2S_CLEAR_TO_SEND GPIO_NUM_21

// Task Priorities
#define POWER_ARDUINO_COMM_PRIORITY 2
#define DRIVE_ARDUINO_COMM_PRIORITY 3
#define TCP_PRIORITY 5
#define READ_VIDEO_FRAME_PRIORITY 7

// Delay timings
#define TCP_INTERVAL 1000
#define POWER_ARDUINO_COMM_INTERVAL 1500
#define DRIVE_ARDUINO_COMM_INTERVAL 1500