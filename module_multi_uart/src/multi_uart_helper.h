#ifndef __MULTI_UART_HELPER_H__
#define __MULTI_UART_HELPER_H__

#include <xccompat.h>

#ifdef __XC__
#define streaming_chanend streaming chanend
#else
#define streaming_chanend chanend
#endif

/**
 * Get time from timer
 * @param t     timer
 * @return      timestamp from timer
 */
unsigned get_time( timer t );

/**
 * Wait for a time period defined by delta
 * @param   t       timer to use
 * @param   delta   time period to wait
 * @return          timestamp on completion of pause
 */
unsigned wait_for( timer t, unsigned delta );

/**
 * Wait until a specific time stamp
 * @param   t       timer to use
 * @param   ts      time stamp to wait until
 * @return          timestamp on completion of pause
 */
unsigned wait_until( timer t, unsigned ts );

/**
 * Send integer value across a streaming channel end
 * @param   c       chanend to use
 * @param   i       integer to send
 */
void send_streaming_int( streaming_chanend c, int i );

/**
 * Get unsigned integer from streaming chanend
 * @param   c       chanend to use
 * @return          value received over the channel
 */
unsigned get_streaming_uint( streaming_chanend c );

/**
 * Send token value across a streaming channel end
 * @param   c       chanend to use
 * @param   i       token to send
 */
void send_streaming_token( streaming_chanend c, char i );

/**
 * Get token from streaming chanend
 * @param   c       chanend to use
 * @return          token received over channel
 */
char get_streaming_token( streaming_chanend c );

#endif /* __MULTI_UART_HELPER_H__ */
