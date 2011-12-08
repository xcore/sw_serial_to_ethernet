/* 
 * This function handles UART port RX
 */

 

#define STACK_SIZE  10
#define CHAN_STRUCT_SIZE 0x6C
#define CHAN_COUNT 8

/* function prototype:
 * void uart_rx_loop( in buffered port:32 pUart, e_uart_rx_chan_state state[], int tick_count[], int bit_count[], int uart_word[], streaming chanend cUART  )
 */
 
//.globl uart_rx_loop, "f{}(ui,ui,ui,ui,ui)"
.globl uart_rx_loop.nstackwords
.globl uart_rx_loop.maxthreads
.globl uart_rx_loop.maxtimers
.globl uart_rx_loop.maxchanends

.linkset uart_rx_loop.nstackwords, STACK_SIZE
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
     * sp[STACK_SIZE+2] => cUART channel
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
	 * r11 => scratch / uart_tx_channel access
	 */
	
	/* clear any events */
	clre
	
	/* set mask */
	ldc r11, 0x0101
	shl r7, r11, 16
	or r7, r7, r11
	
	/* load uart_word pointer */
	ldw r4, sp[STACK_SIZE+1]
	
	/* store root pointers */
	stw r1, sp[8]
	stw r2, sp[9]
	stw r3, sp[10]
	
rx_bit_ep:
    /* initialise channel count */
	ldc r5, 0
	
    /* get data */
	in r6,res[r0]

process_loop:	
	/* get fourBits */
	and r8, r6, r7 // mask off bits
    mkmsk r11, 4
    crc32 r8, r11, r11 // compress bits 
    
    ldaw r11, dp[fourBitLookup] // do lookup
    ldw r8, r11[r8] // get fourBits

	/* check if state is idle (0x0) */
	ldw r11, r1[r5]
	bf r11, idle_process
    
    /* check if tickcount is  < 4 */
	ldc r11, 4
	ldw r10, r2[r5]
	lss r11, r10, r11
	bt r11, data_process // TODO - we assume here that we only have two states

	/* decerement tick_count */
	sub r10, r10, 4
	stw r10, r2[r5]
	
	/* shift port_val, check loop and increment or quit loop */
    shr r6, r6, 1
    ldc r9, CHAN_COUNT
    add r5, r5, 1
    lsu r11, r5, r9 // TODO change to chan count define
    bf r11, rx_bit_ep
    bu process_loop
	
idle_process:
    /* This state detects the start of a start bit by looking for a change in state in the line
     * sampling points are then calculated from this point
     */
    
    /* zero uart_word entry */
    ldc r10, 0
    stw r10, r4[r5]    
    
    /* initial tc */
    ldaw r11, dp[uart_rx_channel]
    ldc r9, CHAN_STRUCT_SIZE
    mul r10, r5, r9 // get struct pointer for channel
    add r11, r11, r10
    
    /* initialise bit count */
    ldw r9, r11[0] // char_len
    stw r9, r3[r5]
    
    /* clocks_per_bit */
    ldw r10, r11[2]
    
    /* use_sample */
    ldw r9, r11[4]
    
    /* calculate tick_count */
    add r9, r9, r10
    
    /* lookup TC value and check for valid start */
    ldaw r10, dp[startBitLookup]
    ldw r10, r10[r8]
    /* check if we have invalid SB */
    mkmsk r8, 32
    eq r8, r8, r10
    bt r8, invalid_start
    
    /* add TC value for swallowed bits */
    add r9, r9, r10
    
    /* store tick_count */
    stw r9, r11[2]
    
    /* store new state */
    ldc r10, 1
    stw r10, r1[r5] // set state to idle
    
    /* shift port_val, check loop and increment or quit loop */
    shr r6, r6, 1
    ldc r9, CHAN_COUNT
    add r5, r5, 1
    lsu r11, r5, r9 // TODO change to chan count define
    bf r11, rx_bit_ep
    bu process_loop
    
invalid_start:    
    ldc r10, 0
    stw r10, r1[r5] // set state to idle
    
    /* shift port_val, check loop and increment or quit loop */
    shr r6, r6, 1
    ldc r9, CHAN_COUNT
    add r5, r5, 1
    lsu r11, r5, r9 // TODO change to chan count define
    bf r11, rx_bit_ep
    bu process_loop
    
check_sb:
    /* TODO - This state checks the validity of the start bit */
    
data_process:
    /* get bit from fourBits - tick_count still in r10 */
    shr r8, r8, r10
    ldc r9, 1
    and r8, r8, r9 // now got the bit
    
    /* store the bit in uart_word */
    ldw r11, r4[r5]
    shl r11, r11, r9
    or r11, r11, r8
    stw r11, r4[r5]
    
    /* decrement bit_count */
    ldw r10, r3[r5]
    sub r10, r10, r9
    stw r10, r3[r5]
    
    /* if bit_count == 0 then change state and get new tick count else calculate new tick count */
    bt r10, dp_calc_tick
    ldc r10, 0
    stw r10, r1[r5] // set state to idle
    
    /* send data word out */
    ldw r9, sp[STACK_SIZE+2]
    out res[r9], r5
    out res[r9], r11
    
dp_calc_tick:
    ldaw r11, dp[uart_rx_channel]
    ldc r9, CHAN_STRUCT_SIZE
    mul r9, r5, r9 // get struct pointer for channel
    add r11, r11, r9
    
    /* clocks_per_bit */
    ldw r11, r11[2]
    sub r11, r11, r10
    stw r11, r2[r5]
    
channel_loop:
    /* shift port_val, check loop and increment or quit loop */
    shr r6, r6, 1
    ldc r9, CHAN_COUNT
    add r5, r5, 1
    lsu r11, r5, r9 // TODO change to chan count define
    bf r11, rx_bit_ep
    bu process_loop
    

	retsp STACK_SIZE

.cc_bottom uart_rx_loop.func
