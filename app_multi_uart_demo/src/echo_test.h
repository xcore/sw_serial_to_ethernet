#ifndef __ECHO_TEST_H__
#define __ECHO_TEST_H__

#define ECHO_BUF_SIZE   256

void uart_rxtx_echo_test( streaming chanend cTxUART, streaming chanend cRxBuf );

void rx_buffering( streaming chanend cRxUART, streaming chanend cRxBuf );


#endif /* __ECHO_TEST_H__ */
