
// Enable WiFi
#define WIFI

// ipv4 or ipv6
#define CONFIG_EXAMPLE_IPV4

// port and ip
#define HOST_IP_ADDR "192.168.1.116"
#define TCP_PORT 4000

// SPI for communication with power and drive system
#define POWER_SPI_MOSI_PIN 13 // Also drive
#define POWER_SPI_MISO_PIN 12 // Also drive
#define POWER_SPI_SCLK_PIN 14 // Also drive

#define POWER_SPI_CS_PIN 26
#define DRIVE_SPI_CS_PIN 27

// Task Priorities
#define POWER_ARDUINO_SPI_PRIORITY