FREEBSD_ROOT_DIR := $(ROOT_DIR)/bsd

FREEBSD_URL := https://github.com/RTBSD/freebsd-src.git
FREEBSD_BRANCH := release/14.3.0
FREEBSD_DIR := $(FREEBSD_ROOT_DIR)/freebsd

CHERIBUILD_URL := https://github.com/RTBSD/cheribuild.git
CHERIBUILD_BRANCH := main
CHERIBUILD_DIR := $(FREEBSD_ROOT_DIR)/cheribuild

freebsd_tool_depends:
	sudo apt install autoconf automake libtool pkg-config \
		clang bison cmake mercurial ninja-build samba flex texinfo \
		time libglib2.0-dev libpixman-1-dev libarchive-dev libarchive-tools \
		libbz2-dev libattr1-dev libcap-ng-dev libexpat1-dev libgmp-dev bc \
		libtinfo5

freebsd_tool_dl:
	@if [ ! -f "clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" ]; then \
		wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz; \
	fi
	@if [ ! -d $(FREEBSD_ROOT_DIR)/build/output/upstream-llvm ]; then \
		mkdir -p $(FREEBSD_ROOT_DIR)/build/output/upstream-llvm && \
		tar -xvf clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
		-C $(FREEBSD_ROOT_DIR)/build/output/upstream-llvm \
		 --strip-components=1; \
	fi

freebsd_src_dl:
	@if [ ! -d $(CHERIBUILD_DIR) ]; then \
		git clone $(CHERIBUILD_URL) $(CHERIBUILD_DIR) -b $(CHERIBUILD_BRANCH) && \
		cd $(CHERIBUILD_DIR) && git checkout d6dc6aec9bf2bff0d35958ebec8a260899a0d062 && \
		git am $(FREEBSD_ROOT_DIR)/patch/cheribuild/*.patch; \
	fi
	@if [ ! -d $(FREEBSD_DIR) ]; then \
		git clone $(FREEBSD_URL) $(FREEBSD_DIR) -b $(FREEBSD_BRANCH) --depth=1 && \
		cd $(FREEBSD_DIR) && git am $(FREEBSD_ROOT_DIR)/patch/freebsd/*.patch; \
	fi

freebsd_aarch64_image:
	$(CHERIBUILD_DIR)/cheribuild.py freebsd-aarch64 disk-image-freebsd-aarch64 \
		--freebsd-with-default-options/debug-kernel \
		--kernel-config GENERIC \
		--source-root $(FREEBSD_ROOT_DIR) \
		--output-root $(FREEBSD_ROOT_DIR)/build/output \
		--build-root $(FREEBSD_ROOT_DIR)/build \
		--freebsd/toolchain upstream-llvm \
		--disk-image-freebsd/extra-files $(FREEBSD_ROOT_DIR)/build/extra-files \
		--disk-image-freebsd/hostname arm64 \
		--disk-image-freebsd/rootfs-type ufs \
		--skip-update
#		--disk-image-freebsd/rockchip \
		--disk-image-freebsd/rockchip_idbloader $(ROOT_DIR)/linux/out/u-boot/idbloader.img \
		--disk-image-freebsd/rockchip_uboot $(ROOT_DIR)/linux/out/u-boot/uboot.img \
		--disk-image-freebsd/rockchip_trust $(ROOT_DIR)/linux/out/u-boot/trust.img
	$(ROOT_DIR)/validate_rk3399_image.sh $(FREEBSD_ROOT_DIR)/build/output/freebsd-aarch64.img

freebsd_aarch64_run:
	@echo "Run FreeBSD(AARCH64)"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=$(FREEBSD_ROOT_DIR)/build/output/freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd -nographic

freebsd_all: freebsd_tool_dl freebsd_src_dl freebsd_aarch64_image