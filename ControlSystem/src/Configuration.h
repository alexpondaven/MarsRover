
// Enable WiFi
#define WIFI

// port and ip
#define HOST_IP_ADDR "192.168.1.116"
#define TCP_PORT 2000

// SPI for communication with power and drive system
#define POWER_SPI_MOSI_PIN 13 // Also drive
#define POWER_SPI_MISO_PIN 12 // Also drive
#define POWER_SPI_SCLK_PIN 14 // Also drive

#define POWER_SPI_CS_PIN 26
#define DRIVE_SPI_CS_PIN 27

// Task Priorities
#define POWER_ARDUINO_SPI_PRIORITY 2
#define DRIVE_ARDUINO_SPI_PRIORITY 3
#define TCP_PRIORITY 5

// Delay timings
#define TCP_INTERVAL 1000
#define POWER_ARDUINO_SPI_INTERVAL 1500
#define DRIVE_ARDUINO_SPI_INTERVAL 1500