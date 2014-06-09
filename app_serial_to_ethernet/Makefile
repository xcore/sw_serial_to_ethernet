# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = SLICEKIT-L16

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name

APP_NAME = 

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.

COMMA = ,
ifneq ($(STATIC_IP),)
STATIC_IP_FLAGS = -DSTATIC_IP={$(subst .,$(COMMA),$(STATIC_IP))}
endif

XCC_FLAGS_Release = -O3 -save-temps -g -report -Xmapper --map -Xmapper MAPFILE -lflash $(STATIC_IP_FLAGS)
XCC_FLAGS_Debug = -O0 -save-temps -g -report -Xmapper --map -Xmapper MAPFILE -lflash $(STATIC_IP_FLAGS)

XCC_C_FLAGS_Release = $(XCC_FLAGS) -Os
XCC_C_FLAGS_Debug = $(XCC_FLAGS) -O0

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = module_multi_uart module_webserver module_xtcp module_slicekit_support
USED_MODULES += module_xc_ptr module_mutual_thread_comm
USED_MODULES += module_ethernet_board_support module_otp_board_info

# This uses the tcp mac filtering in module_xtcpxc
USE_XTCP_MAC_CUSTOM_FILTER=1

WEB_ROOT_DIR = web

.PHONY: flash

flash:
	xflash --boot-partition-size 0x10000 $(BIN_DIR)/$(APP_NAME).xe --data $(BIN_DIR)/web_data.bin

#=============================================================================
#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
ifneq ($(wildcard $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common),)


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
