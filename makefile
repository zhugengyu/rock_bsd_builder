export ROOT_DIR := $(realpath $(CURDIR))

include $(ROOT_DIR)/linux/linux.mk
include $(ROOT_DIR)/bsd/firmware/firmware.mk
include $(ROOT_DIR)/bsd/freebsd.mk
include $(ROOT_DIR)/bsd/netbsd.mk