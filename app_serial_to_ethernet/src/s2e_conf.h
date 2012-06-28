#define UART_RX_MAX_PACKET_SIZE 128
#define UART_RX_MIN_PACKET_SIZE 32
#define TELNET_UART_BASE_PORT 46


// Debugging Options

// Enable this option to output a '!' when the uart RX buffer overflows
//#define S2E_DEBUG_OVERFLOW 1

// Enable this option to send the incoming data
// from uart 0 to every telnet connection
//#define S2E_DEBUG_BROADCAST_UART_0 1

// Enable this option to fill unused buffer area with watermark characters
//#define S2E_DEBUG_WATERMARK_UNUSED_BUFFER_AREA 1
