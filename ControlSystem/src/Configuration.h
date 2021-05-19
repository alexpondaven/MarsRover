
// Enable WiFi
#define WIFI

// port and ip
#define HOST_IP_ADDR "192.168.1.116"
#define TCP_PORT 2000

// SPI for communication with power and drive system
// #define POWER_SPI_MOSI_PIN 13 // Also drive
// #define POWER_SPI_MISO_PIN 12 // Also drive
// #define POWER_SPI_SCLK_PIN 14 // Also drive

// #define POWER_SPI_CS_PIN 26
// #define DRIVE_SPI_CS_PIN 27

#define POWER_UART_TX_PIN 17
#define POWER_UART_RX_PIN 16
#define POWER_UART_CTS_PIN 18
#define POWER_UART_RTS_PIN 19

#define DRIVE_UART_TX_PIN 25
#define DRIVE_UART_RX_PIN 26
#define DRIVE_UART_CTS_PIN 27
#define DRIVE_UART_RTS_PIN 14


// Task Priorities
#define POWER_ARDUINO_COMM_PRIORITY 2
#define DRIVE_ARDUINO_COMM_PRIORITY 3
#define TCP_PRIORITY 5

// Delay timings
#define TCP_INTERVAL 1000
#define POWER_ARDUINO_COMM_INTERVAL 1500
#define DRIVE_ARDUINO_COMM_INTERVAL 1500