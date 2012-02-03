TOOLS_ROOT = $(installpath)
include $(TOOLS_ROOT)/src/MakefileUnix.mak

ifndef M32
M32 = -m32
endif

APP_NAME=multi_uart_demo
PLUGIN_NAME=uart_test
OBJS = uart_test.o

all: $(DLLDIR)/$(PLUGIN_NAME)$(DLLEXT)

$(DLLDIR)/$(PLUGIN_NAME)$(DLLEXT): $(OBJS)
	$(CCPP) $(M32) $(OBJS) -shared -o $(DLLDIR)/$(PLUGIN_NAME)$(DLLEXT) $(LIBS) $(EXTRALIBS)

%.o: %.cpp
	$(CPP) $(M32) $(CPPFLAGS) -c $< -o $@ -I$(TOOLS_ROOT)/include

clean: 
	rm -rf $(OBJS)
	rm -rf $(BINDIR)/$(PLUGIN_NAME).*

runsim:
	xsim -t --trace-to uart_trace.log --plugin uart_test.so "0 X0D14 0 X0D00" --vcd-tracing "-o uart_sim.vcd -cycles -ports -ports-detailed" ../../app_multi_uart_demo/bin/$(APP_NAME).xe
