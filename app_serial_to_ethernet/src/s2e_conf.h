#define UART_RX_MAX_PACKET_SIZE 1100 //550 for local hosts
#define UART_RX_MIN_PACKET_SIZE 800 //400 for local hosts
#define TELNET_UART_BASE_PORT 46
#define SW_FC_CTRL  1

#if SW_FC_CTRL
#define WATERMARK_LEVEL 60
#define UART_RX_MAX_WATERMARK   (UART_RX_MAX_PACKET_SIZE-WATERMARK_LEVEL)
#define UART_RX_MIN_WATERMARK   WATERMARK_LEVEL

/* Ensure to update 'sw_fc_in' value if the below values are modified, */
#define XOFF    0x13    //Pause Transmission
#define XON     0x11    //Resume Transmission
#endif
// Debugging Options

// Enable this option to output a '!' when the uart RX buffer overflows
//#define S2E_DEBUG_OVERFLOW 1

// Enable this option to send the incoming data
// from uart 0 to every telnet connection
//#define S2E_DEBUG_BROADCAST_UART_0 1

// Enable this option to fill unused buffer area with watermark characters
//#define S2E_DEBUG_WATERMARK_UNUSED_BUFFER_AREA 1
