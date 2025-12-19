NETBSD_ROOT_DIR := $(ROOT_DIR)/bsd

NETBSD_URL := https://github.com/RTBSD/NetBSD-src.git
NETBSD_BRANCH := netbsd-10
NETBSD_DIR := $(NETBSD_ROOT_DIR)/netbsd

NETBSD_AARCH64_MARCH := evbarm
NETBSD_AARCH64_ARCH := aarch64
NETBSD_AARCH64_KERNCONFIG := GENERIC64

export HOST_UNAME_S!=  uname -s
export HOST_UNAME_R!=  uname -r
export HOST_UNAME_P!=  uname -p

NETBSD_AARCH64_IMAGES := $(NETBSD_ROOT_DIR)/build/netbsd-aarch64-build/releasedir/$(NETBSD_AARCH64_MARCH)-$(NETBSD_AARCH64_ARCH)/binary/gzimg
NETBSD_AARCH64_KERNELS := $(NETBSD_ROOT_DIR)/build/netbsd-aarch64-build/sys/arch/$(NETBSD_AARCH64_MARCH)/compile
NETBSD_AARCH64_TOOLS := $(NETBSD_ROOT_DIR)/build/netbsd-aarch64-build/tooldir.$(HOST_UNAME_S)-$(HOST_UNAME_R)-$(HOST_UNAME_P)

netbsd_src_dl:
	@if [ ! -d $(NETBSD_DIR) ]; then \
		git clone $(NETBSD_URL) $(NETBSD_DIR) -b $(NETBSD_BRANCH) --depth=1 && \
		cd $(NETBSD_DIR) && git am $(NETBSD_ROOT_DIR)/patch/netbsd/*.patch; \
	fi

netbsd_aarch64_image:
	@cd $(NETBSD_DIR) && \
		./build.sh -U -u -j12 \
		-O $(NETBSD_ROOT_DIR)/build/netbsd-aarch64-build \
		-m $(NETBSD_AARCH64_MARCH) \
		-a $(NETBSD_AARCH64_ARCH) \
		releasekernel=$(NETBSD_AARCH64_KERNCONFIG) \
		tools release 
	@gunzip -d $(NETBSD_AARCH64_IMAGES)/arm64.img.gz
	@cp $(NETBSD_AARCH64_IMAGES)/arm64.img ./netbsd-aarch64.img

netbsd_aarch64_kernel:
	@cd $(NETBSD_DIR) && \
		./build.sh -U -u -j12 \
		-O $(NETBSD_ROOT_DIR)/build/netbsd-aarch64-build \
		-m $(NETBSD_AARCH64_MARCH) \
		-a $(NETBSD_AARCH64_ARCH) \
		releasekernel=$(NETBSD_AARCH64_KERNCONFIG) \
		build
	@cp $(NETBSD_AARCH64_KERNELS)/$(NETBSD_AARCH64_KERNCONFIG)/netbsd . -f

netbsd_amd64_image:
	@cd $(NETBSD_DIR) &&  \
		./build.sh -U -u -j12 \
		-O $(NETBSD_ROOT_DIR)/build/netbsd-amd64-build \
		-m amd64 \
		releasekernel=GENERIC \
		release live-image

netbsd_all: netbsd_src_dl netbsd_aarch64_image