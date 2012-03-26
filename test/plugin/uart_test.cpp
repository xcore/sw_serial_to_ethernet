/*
 * Copyright XMOS Limited - 2009
 *
 * This plugin operates on a pin to generate a stream of data at 115200bps configured for 8-E-1.
 * It emulates a UART TX
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "uart_test.h"

#define MAX_INSTANCES 256
#define MAX_BYTES 1024
#define CHECK_STATUS if (status != XSI_STATUS_OK) return status

#define ARG_COUNT 6
/* 500000000/115200 = 4340.277 */
/* 500000000/115205 = 4340.089 */
/* 500000000/116352 = 4297.305 (1% faster)*/
#define CLOCK_TICKS_115KBPS 4297
#define CLOCK_TICKS_ERROR   305
#define EXT_CLOCK_TICKS_1_8432MHZ 135 // 135.633
/*
 * Types
 */
 
enum UartTxState
{
  INITIAL_PAUSE,
  IDLE,
  DRIVE_WAIT,
  OUTPUT,
  HALT
};

struct UartTxInstance
{
  XsiCallbacks *xsi;
  const char *uart_package;
  const char *uart_pin;
  const char *uart_rx_pin;
  
  const char *ext_clk_pkg;
  const char *ext_clk_pin;
  
  /* output state */
  unsigned current_data;
  unsigned current_data_len;
  unsigned tick_count;
  unsigned next_tick_count;
  unsigned out_count;
  unsigned tick_error;
  UartTxState state;
  
  /* input state */
  unsigned rx_current_data;
  unsigned rx_data_len;
  unsigned rx_tick_count;
  
  /* ext clk src state */
  unsigned ext_clk_src_tick_count;
  unsigned ext_clk_src_tick_error;
  unsigned ext_clk_src_tick_target;
  unsigned ext_clk_value;
  
  unsigned start_bit_polarity;
};

/*
 * Static data
 */
static size_t s_num_instances = 0;
static UartTxInstance s_instances[MAX_INSTANCES];

/*
 * Static functions
 */
static void print_usage();
static XsiStatus split_args(const char *args, char *argv[]);

/*
 * Create
 */
XsiStatus plugin_create(void **instance, XsiCallbacks *xsi, const char *arguments)
{
  if (s_num_instances >= MAX_INSTANCES) {
    fprintf(stderr, "ERROR: too many instances of plugin (max %d)\n", MAX_INSTANCES);
    return XSI_STATUS_INVALID_INSTANCE;
  }
  
  // Use the entry in the instances list to identify this instance
  *instance = (void*)s_num_instances;

  char *argv[ARG_COUNT];
  XsiStatus status = split_args(arguments, argv);
  if (status != XSI_STATUS_OK) {
  	print_usage();
  	return status;
  }
  
  // Store pin information
  s_instances[s_num_instances].uart_package = argv[0];
  s_instances[s_num_instances].uart_pin = argv[1];
  s_instances[s_num_instances].uart_rx_pin = argv[2];
  
  s_instances[s_num_instances].ext_clk_pkg = argv[3];
  s_instances[s_num_instances].ext_clk_pin = argv[4];
  
  if (atoi(argv[4]) != 0 && atoi(argv[4]) != 1)
  {
      printf("Invalid polarity setting - %d\n", atoi(argv[5]));
      return XSI_STATUS_INVALID_ARGS;
  }
  
  s_instances[s_num_instances].start_bit_polarity = atoi(argv[5]);
  
  s_instances[s_num_instances].state = INITIAL_PAUSE;
  s_instances[s_num_instances].tick_count = 0;
  s_instances[s_num_instances].tick_error = 0;
  
  s_instances[s_num_instances].ext_clk_src_tick_count = 0;
  s_instances[s_num_instances].ext_clk_src_tick_error = 0;
  s_instances[s_num_instances].ext_clk_src_tick_target = EXT_CLOCK_TICKS_1_8432MHZ;
  s_instances[s_num_instances].ext_clk_value = 0;
  
  s_instances[s_num_instances].xsi = xsi;
  s_num_instances++;
  
  printf("Initiated UART test plugin...\n");
  
  return XSI_STATUS_OK;
}

/*
 * Clock
 */
XsiStatus plugin_clock(void *instance)
{
  size_t instance_num = (size_t)instance;
  if (instance_num >= s_num_instances) {
    return XSI_STATUS_INVALID_INSTANCE;
  }

  XsiStatus status = XSI_STATUS_OK;

  XsiCallbacks *xsi = s_instances[instance_num].xsi;
  const char *uart_package = s_instances[instance_num].uart_package;
  const char *uart_pin     = s_instances[instance_num].uart_pin;
  const char *ext_clk_package = s_instances[instance_num].ext_clk_pkg;
  const char *ext_clk_pin     = s_instances[instance_num].ext_clk_pin;
  UartTxState state        = s_instances[instance_num].state;

  unsigned value = 0;
  
  UartTxState next_state;
  
  unsigned int data;
  unsigned int parity;
  
  static unsigned int char_count = 0;

  static unsigned int first_time_flg = 0;
  
  if (first_time_flg == 0)
  {
  	first_time_flg = 1;
	/* drive other pins on 8B */
	status = xsi->drive_pin("0", "X0D14", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
	status = xsi->drive_pin("0", "X0D15", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
    status = xsi->drive_pin("0", "X0D16", !s_instances[instance_num].start_bit_polarity);
    CHECK_STATUS;
    status = xsi->drive_pin("0", "X0D17", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
	status = xsi->drive_pin("0", "X0D18", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
	status = xsi->drive_pin("0", "X0D19", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
	status = xsi->drive_pin("0", "X0D20", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
	status = xsi->drive_pin("0", "X0D21", !s_instances[instance_num].start_bit_polarity);
	CHECK_STATUS;
	
	printf("Polarity of start bit is %d\n", s_instances[instance_num].start_bit_polarity);
  }
  
  /* external clock */
  if (s_instances[instance_num].ext_clk_src_tick_count < s_instances[instance_num].ext_clk_src_tick_target)
  {
      s_instances[instance_num].ext_clk_src_tick_count++;
  }
  
  else
  {
      /* output clock value */
      value = s_instances[instance_num].ext_clk_value;
      status = xsi->drive_pin(ext_clk_package, ext_clk_pin, value);
      CHECK_STATUS;
      s_instances[instance_num].ext_clk_value ^= 1;
      
      /* reset tick count */
      s_instances[instance_num].ext_clk_src_tick_count = 0;
      
      /* error */
      s_instances[instance_num].ext_clk_src_tick_error += 633;
      s_instances[instance_num].ext_clk_src_tick_target = EXT_CLOCK_TICKS_1_8432MHZ;
      if (s_instances[instance_num].ext_clk_src_tick_error > 1000)
      {
          s_instances[instance_num].ext_clk_src_tick_error %= 1000;
          s_instances[instance_num].ext_clk_src_tick_target += 1;
      }
      
  }
  
  
  value = 0;
  
  if (char_count > 300 && state != HALT)
  {
      printf("Halting...");
  }
  
  if (char_count > 300)
  {
      state = HALT;
  }
  
  
  
  /* state machine for uart output */
  switch (state) 
  {
    case INITIAL_PAUSE:
      s_instances[instance_num].tick_count++;
      if (s_instances[instance_num].tick_count < 100000)
      {
          status = xsi->drive_pin(uart_package, uart_pin, !s_instances[instance_num].start_bit_polarity);      
          CHECK_STATUS;
          next_state = INITIAL_PAUSE;
      }
      else
      {
          next_state = IDLE;
      }
      
      break;
    case IDLE:
        int start_bit;
        int stop_bit;
        
        data = (unsigned int)rand() % 256; // generate 0-255
        //data = 0x55;
        data &= 0xFF; // ensure 8 bits
        
        /* calculate parity */
        parity = data & 1;
        for (int i = 1; i < 8; i++)
            parity ^= ((data >> i) & 1);
        
        /* generate UART Word */
        s_instances[instance_num].current_data_len = 11; // START + DATA(8) + PARITY + STOP
        /* build word */
        s_instances[instance_num].current_data = 0;
        
        /* work out stop/start bit polarity */
        switch (s_instances[instance_num].start_bit_polarity)
        {
            case 0: start_bit = 0; stop_bit = 1; break;
            case 1: start_bit = 1; stop_bit = 0; break;
            default: start_bit = 0; stop_bit = 1; break;
        }
        
        s_instances[instance_num].current_data |= (stop_bit<<11) | (stop_bit<<10) | (parity<<9) | (data<<1) | start_bit;
        
        s_instances[instance_num].tick_count = 0;
        s_instances[instance_num].out_count = 0;
        
        printf("[%d] Generated byte 0x%x => 0x%x\n", ++char_count, data, s_instances[instance_num].current_data);
        
        /* output first bit */
        value = s_instances[instance_num].current_data & 1;
        status = xsi->drive_pin(uart_package, uart_pin, value);      
        CHECK_STATUS;
        
        /* setup next tick */
        s_instances[instance_num].tick_error += CLOCK_TICKS_ERROR;
        if (s_instances[instance_num].tick_error > 1000)
        {
            s_instances[instance_num].next_tick_count = CLOCK_TICKS_115KBPS+1;
            s_instances[instance_num].tick_error = s_instances[instance_num].tick_error % 1000;
        } else {
            s_instances[instance_num].next_tick_count = CLOCK_TICKS_115KBPS;
        }
        
        next_state = OUTPUT;
        
        break;
        
    case OUTPUT:
        s_instances[instance_num].tick_count++;
        
        if (s_instances[instance_num].tick_count == s_instances[instance_num].next_tick_count) 
        {
            s_instances[instance_num].tick_error += CLOCK_TICKS_ERROR;
            if (s_instances[instance_num].tick_error > 1000)
            {
                s_instances[instance_num].next_tick_count = CLOCK_TICKS_115KBPS+1;
                s_instances[instance_num].tick_error = s_instances[instance_num].tick_error % 1000;
            } else {
                s_instances[instance_num].next_tick_count = CLOCK_TICKS_115KBPS+1;
            }
                
            /* reset bit tick */
            s_instances[instance_num].tick_count = 0;
            
            /* get pin value */
            s_instances[instance_num].current_data >>= 1;
            value = s_instances[instance_num].current_data & 1;
        
            /* output to pin */
            status = xsi->drive_pin(uart_package, uart_pin, value);      
            CHECK_STATUS;
            
            /* see if we reached the end of out data yet */
            s_instances[instance_num].current_data_len--;
            if (s_instances[instance_num].current_data_len == 0)
            {
                next_state = IDLE;
                printf("Done byte\n");
            }
            else
                next_state = OUTPUT;
        }
        else
        {
            if (s_instances[instance_num].tick_error > 1000)
            {
                s_instances[instance_num].next_tick_count += 1;
                s_instances[instance_num].tick_error = s_instances[instance_num].tick_error % 1000;
            }
            next_state = OUTPUT;
        }
        break;
    case HALT:
        //printf("Sim complete...");
        //return XSI_STATUS_DONE;
        next_state = HALT;
        break;
    default:
        printf("ERROR: Invalid State!\n");
        return XSI_STATUS_DONE;
        break;
  }
  
  s_instances[instance_num].state = next_state;
  
  return status;
}

/*
 * Notify
 */
XsiStatus plugin_notify(void *instance, int type, unsigned arg1, unsigned arg2)
{
  return XSI_STATUS_OK;
}

/*
 * Terminate
 */
XsiStatus plugin_terminate(void *instance)
{
  if ((size_t)instance >= s_num_instances) {
    return XSI_STATUS_INVALID_INSTANCE;
  }
  return XSI_STATUS_OK;
}

/*
 * Usage
 */
static void print_usage()
{
  fprintf(stderr, "Usage:\n");
  fprintf(stderr, "  Uart_test.dll/so <package> <UART RX pin> <UART TX pin> <package> <ext clk pin>  <start_bit_polarity>\n");
}

/*
 * Split args
 */
static XsiStatus split_args(const char *args, char *argv[])
{
  char buf[MAX_BYTES];

  int arg_num = 0;
  while (arg_num < ARG_COUNT ) {
    char *buf_ptr = buf;
    
    while (isspace(*args))
      args++;
      
    if (*args == '\0')
      return XSI_STATUS_INVALID_ARGS;

    while (*args != '\0' && !isspace(*args))
      *buf_ptr++ = *args++;

    *buf_ptr = '\0';
    argv[arg_num] = strdup(buf);
    arg_num++;
  }

  while (isspace(*args))
    args++;
  
  if (arg_num != ARG_COUNT  || *args != '\0')
    return XSI_STATUS_INVALID_ARGS;
  else
    return XSI_STATUS_OK;
}

