ROCK_LINUX_DIR := $(ROOT_DIR)/linux
ROCK_LINUX_OUTPUT_DIR := $(ROCK_LINUX_DIR)/out

ROCK_LINUX_TOOL_URL := https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
ROCK_LINUX_TOOL_PACK := gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz

ROCK_LINUX_SRC_DIR := $(ROCK_LINUX_DIR)

ROCK_LINUX_BUILD_DIR := $(ROCK_LINUX_SRC_DIR)/build
ROCK_LINUX_BUILD_URL := https://github.com/radxa/build.git
ROCK_LINUX_BUILD_BRANCH := debian
ROCK_LINUX_BUILD_TARGET := tb-rk3399prod
#ROCK_LINUX_BUILD_TARGET := rockpin10

ROCK_LINUX_UBOOT_DIR := $(ROCK_LINUX_SRC_DIR)/u-boot
ROCK_LINUX_UBOOT_URL := https://github.com/radxa/u-boot.git
ROCK_LINUX_UBOOT_BRANCH := rk3399-pie-gms-express-baseline

ROCK_LINUX_RKBIN_DIR := $(ROCK_LINUX_SRC_DIR)/rkbin
ROCK_LINUX_RKBIN_URL := https://github.com/radxa/rkbin.git
ROCK_LINUX_RKBIN_BRANCH := develop-v2025.04

ROCK_LINUX_KERNEL_DIR := $(ROCK_LINUX_SRC_DIR)/kernel
ROCK_LINUX_KERNEL_URL := https://github.com/radxa/kernel.git
ROCK_LINUX_KERNEL_BRANCH := rk3399pro-toybrick-stable

ROCK_LINUX_ROOTFS_URL := https://github.com/zhugengyu/rock_bsd_builder/releases/download/0.0/linaro-rootfs-arm64.7z
ROCK_LINUX_ROOTFS_PACK := $(ROCK_LINUX_OUTPUT_DIR)/linaro-rootfs-arm64.7z
ROCK_LINUX_ROOTFS_IMG := $(ROCK_LINUX_OUTPUT_DIR)/linaro-rootfs.img

CROSS_COMPILE_TARGETS = rock_linux_depends rock_linux_dl rock_linux_uboot rock_linux_kernel rock_linux_image rock_linux_all

ifneq (,$(filter $(CROSS_COMPILE_TARGETS),$(MAKECMDGOALS)))
    export CROSS_COMPILE := $(ROCK_LINUX_OUTPUT_DIR)/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
    export PATH := $(ROCK_LINUX_OUTPUT_DIR)/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin:$(PATH)
    
    $(info === Cross Compiler for: $(MAKECMDGOALS) ===)
endif

# Ubuntu 20.04 AMD64 tested
rock_linux_depends:
	sudo apt-get install wget gcc-aarch64-linux-gnu device-tree-compiler libncurses5 libncurses5-dev build-essential libssl-dev mtools
	sudo apt-get install bc python dosfstools p7zip-full

rock_linux_dl:
	mkdir -p $(ROCK_LINUX_OUTPUT_DIR)
	@if [ ! -f $(CROSS_COMPILE)gcc ]; then \
		cd $(ROCK_LINUX_OUTPUT_DIR) && \
		wget $(ROCK_LINUX_TOOL_URL) && \
		sudo tar xvf $(ROCK_LINUX_TOOL_PACK) -C $(ROCK_LINUX_OUTPUT_DIR); \
	fi
	@if [ ! -d $(ROCK_LINUX_BUILD_DIR) ]; then \
		git clone $(ROCK_LINUX_BUILD_URL) $(ROCK_LINUX_BUILD_DIR) -b $(ROCK_LINUX_BUILD_BRANCH) && \
		cd $(ROCK_LINUX_BUILD_DIR) && git checkout 763eec0c7c29af9f60cca5e98eb1db6031b11976; \
	fi
	@if [ ! -d $(ROCK_LINUX_RKBIN_DIR) ]; then \
		git clone $(ROCK_LINUX_RKBIN_URL) $(ROCK_LINUX_RKBIN_DIR) -b $(ROCK_LINUX_RKBIN_BRANCH) && \
		cd $(ROCK_LINUX_RKBIN_DIR) && git checkout e8e5d791093d7d229d29a54e23c7d541ff076d17; \
	fi
	@if [ ! -d $(ROCK_LINUX_UBOOT_DIR) ]; then \
		git clone $(ROCK_LINUX_UBOOT_URL) $(ROCK_LINUX_UBOOT_DIR) -b $(ROCK_LINUX_UBOOT_BRANCH); \
	fi
	@if [ ! -d $(ROCK_LINUX_KERNEL_DIR) ]; then \
		git clone $(ROCK_LINUX_KERNEL_URL) $(ROCK_LINUX_KERNEL_DIR) -b $(ROCK_LINUX_KERNEL_BRANCH) --depth=1; \
	fi
	@if [ ! -f $(ROCK_LINUX_ROOTFS_IMG) ]; then \
		cd $(ROCK_LINUX_OUTPUT_DIR) && \
		wget $(ROCK_LINUX_ROOTFS_URL) && \
		7z x $(ROCK_LINUX_ROOTFS_PACK); \
	fi

rock_linux_uboot:
	cd $(ROCK_LINUX_DIR) && ./build/mk-uboot.sh $(ROCK_LINUX_BUILD_TARGET)

rock_linux_kernel:
	cd $(ROCK_LINUX_DIR) && ./build/mk-kernel.sh $(ROCK_LINUX_BUILD_TARGET)

rock_linux_image:
	cd $(ROCK_LINUX_DIR) && ./build/mk-image.sh -c rk3399pro -t system -r $(ROCK_LINUX_ROOTFS_IMG)
	cd $(ROCK_LINUX_DIR) && ls ./out
	cp $(ROCK_LINUX_DIR)/out/system.img \
		$(ROOT_DIR)/$(ROCK_LINUX_BUILD_TARGET)-$(ROCK_LINUX_BUILD_BRANCH)-sd.img -f

rock_linux_all: rock_linux_dl rock_linux_uboot rock_linux_kernel rock_linux_image