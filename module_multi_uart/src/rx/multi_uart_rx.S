/* 
 * This function handles UART port RX
 */

 

#define STACK_SIZE  10
#define CHAN_STRUCT_SIZE 0x6C

/* function prototype:
 * void uart_rx_loop( in buffered port:32 pUart, e_uart_rx_chan_state state[], int tick_count[], int bit_count[], int uart_word[]  )
 */
 
.globl uart_rx_loop, "f{}(ui,ui,ui,ui)"
.globl uart_rx_loop.nstackwords
.globl uart_rx_loop.maxthreads
.globl uart_rx_loop.maxtimers
.globl uart_rx_loop.maxchanends

.linkset uart_rx_loop.nstackwords, STACK_USE
.linkset uart_rx_loop.maxchanends, 0
.linkset uart_rx_loop.maxtimers, 0
.linkset uart_rx_loop.maxthreads, 0

.globl uart_rx_loop

.text
.cc_top uart_rx_loop.func, uart_rx_loop

uart_rx_loop:
    entsp STACK_SIZE

    /* stack usage:
     * sp[1] => callee save r4
     * sp[2] => callee save r5
     * sp[3] => callee save r6
     * sp[4] => callee save r7
     * sp[5] => callee save r8
     * sp[6] => callee save r9
     * sp[7] => callee save r10
     * sp[8] => state pointer
     * sp[9] => tick_count pointer
     * sp[10] => bit_count pointer
     * sp[STACK_SIZE+1] => uart_word pointer
     */

    /* callee save */
	stw r4, sp[1]	
	stw r5, sp[2]
	stw r6, sp[3]
	stw r7, sp[4]
	stw r8, sp[5]
	stw r9, sp[6]
	stw r10, sp[7]
	
	/* register usage 
	 * r0  => port
	 * r1  => state pointer
	 * r2  => tick_count pointer
	 * r3  => bit_count pointer
	 * r4  => uart_word pointer
	 * r5  => channel id
	 * r6  => port_val
	 * r7  => mask
	 * r8  => fourBit / bit
	 * r9  => scratch
	 * r10 => scratch
	 * r11 => scratch
	 */
	
	/* clear any events */
	clre
	
	/* set mask */
	ldc r11, 0x0101
	shl r10, r11, 16
	or r10, r10, r11
	
	/* load uart_word pointer */
	ldw r4, sp[STACK_SIZE+1]
	
	/* store root pointers */
	stw r1, sp[8]
	stw r2, sp[9]
	stw r3, sp[10]
	
rx_bit_loop:
    /* initialise channel count */
	ldc r5, 0
	
    /* get data */
    .xtalabel xtaendpoint "rx_bit_ep"
	in r6,res[r0]
	
process_loop:
	/* check if state is idle (0x0) */
	ldw r11, r1[r5]
	bf r11, idle_process
    
    /* check if tickcount is  < 4 */
	ldc r11, 4
	ldw r10, r2[r5]
	lss r11, r10, r11
	bt r11, data_process

	sub r10, r10, 4
	stw r7, r2[r5]
	
idle_process:
    and r8, r6, r7 // mask off bits
    mkmsk r11, 4
    crc r8, r11, r11 // compress bits 
    
    ldaw r11, dp[fourBitLookup] // do lookup
    ldw r8, r11[r8] // get fourBits
    
    /* zero uart_word entry */
    ldaw r11, dp[uart_word]
    stw 0. r11[r5]    
    
    /* initial tc */
    ldaw r11, dp[uart_rx_channel]
    mul r10, r5, CHAN_STRUCT_SIZE // get struct pointer for channel
    add r11, r11, r10
    
    /* initialise bit count */
    ldaw r10, dp[bit_count]
    ldw r9, r11[0] // char_len
    stw r9, r10[r5]
    
    /* clocks_per_bit */
    ldw r10, r11[2]
    
    /* use_sample */
    ldw r9, r11[4]
    
    /* calculate tick_count */
    add r9, r9, r10
           
    ldc r11,0
    eq r11, r8, r11
    bt r11, case_0b0000
    
    mkmsk r11, 1
    eq r11, r8, r11
    bt r11, case_0b0001
    
    mkmsk r11,2
    eq r11, r8, r11
    bt r11, case_0b0011
    
    mkmsk r11,3
    eq r11, r8, r11
    bt r11, case_0b0111
    
    stw 0, r1[r5] // set state to idle
    
case_0b0000:
    /* store tick_count */
    stw r9, r11[2]
    
    /* next state */
    stw 1, r1[r5]
    
    /* check loop and increment or quit loop */
    lsu r11, r5, 4 // TODO change to chan count define
    bf r11, rx_bit_loop
    add r5, r5, 1
    bu process_loop
    
case_0b0001:
    /* apply tick_count correction for swallowed bits */
    add r9, r9, 1
    
    /* store tick_count */
    stw r9, r11[2]
    
    /* next state */
    stw 1, r1[r5]
    
    /* check loop and increment or quit loop */
    lsu r11, r5, 4 // TODO change to chan count define
    bf r11, rx_bit_loop
    add r5, r5, 1
    bu process_loop

case_0b0011:
    /* apply tick_count correction for swallowed bits */
    add r9, r9, 2
    
    /* store tick_count */
    stw r9, r11[2]
    
    /* next state */
    stw 1, r1[r5]
    
    /* check loop and increment or quit loop */
    lsu r11, r5, 4 // TODO change to chan count define
    bf r11, rx_bit_loop
    add r5, r5, 1
    bu process_loop

case_0b0111:
    /* apply tick_count correction for swallowed bits */
    add r9, r9, 3
    
    /* store tick_count */
    stw r9, r11[2]
    
    /* next state */
    stw 1, r1[r5]
    
    /* check loop and increment or quit loop */
    lsu r11, r5, 4 // TODO change to chan count define
    bf r11, rx_bit_loop
    add r5, r5, 1
    bu process_loop
    
data_process:
    
    
channel_loop:
    /* check loop and increment or quit loop */
    lsu r11, r5, 4 // TODO change to chan count define
    bf r11, rx_bit_loop
    add r5, r5, 1
    bu process_loop
    

	retsp STACK_SIZE

.cc_bottom uart_rx_loop.func
