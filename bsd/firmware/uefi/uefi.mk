# Makefile for Rockchip RK3399 UEFI Firmware

# UEFI firmware URLs and files
UEFI_URL_BASE = https://personalbsd.org/download/UEFI-RK3399
IDBLOADER_BIN = idbloader.img
RK3399_SDK_UEFI_IMG = RK3399_SDK_UEFI.img
TRUST_IMG = trust.img
ESP_SIZE_MB = 112

# Partition configuration based on GPT layout
LOADER1_START_SECTOR = 64
LOADER1_END_SECTOR = 8063
RESERVED1_START_SECTOR = 8064
RESERVED1_END_SECTOR = 8191
RESERVED2_START_SECTOR = 8192
RESERVED2_END_SECTOR = 16383
LOADER2_START_SECTOR = 16384
LOADER2_END_SECTOR = 24575
ATF_START_SECTOR = 24576
ATF_END_SECTOR = 32767
ESP_START_SECTOR = 32768
ESP_END_SECTOR = 262143

# Calculate sizes
SECTOR_SIZE = 512
TOTAL_SIZE_SECTORS = $(shell echo $$((${ESP_END_SECTOR} + 1)))
TOTAL_SIZE_MB = $(shell echo $$(((${TOTAL_SIZE_SECTORS} * ${SECTOR_SIZE}) / 1024 / 1024)))

UEFI_IMAGE = rk3399-uefi-firmware.img
SDCARD_DEVICE ?= /dev/sdX

# Check if file exists
FILE_EXISTS = test -f $1

# Download single file if not exists
define download_if_needed
	@if $(call FILE_EXISTS,$(1)); then \
		echo "File $(1) already exists, skipping download"; \
	else \
		echo "Downloading $(1)..."; \
		wget -q --show-progress $(2) -O $(1); \
	fi
endef

# Show partition layout information
.PHONY: uefi_info
uefi_info:
	@echo "Rockchip RK3399 UEFI firmware partition layout:"
	@echo "  Loader1:    Sectors $(LOADER1_START_SECTOR)-$(LOADER1_END_SECTOR) -> $(IDBLOADER_BIN)"
	@echo "  Reserved1:  Sectors $(RESERVED1_START_SECTOR)-$(RESERVED1_END_SECTOR)"
	@echo "  Reserved2:  Sectors $(RESERVED2_START_SECTOR)-$(RESERVED2_END_SECTOR)"
	@echo "  Loader2:    Sectors $(LOADER2_START_SECTOR)-$(LOADER2_END_SECTOR) -> $(RK3399_SDK_UEFI_IMG)"
	@echo "  ATF:        Sectors $(ATF_START_SECTOR)-$(ATF_END_SECTOR) -> $(TRUST_IMG)"
	@echo "  ESP:        Sectors $(ESP_START_SECTOR)-$(ESP_END_SECTOR)"
	@echo "  Total image size: $(TOTAL_SIZE_MB)MB ($(TOTAL_SIZE_SECTORS) sectors)"

# Main target: create UEFI firmware image
.PHONY: uefi_image
uefi_image: uefi_info $(UEFI_IMAGE)
	@echo "RK3399 UEFI firmware image created: $(UEFI_IMAGE)"
	@echo "Image information:"
	ls -lh $(UEFI_IMAGE)

# Create firmware image (depends on downloaded files)
$(UEFI_IMAGE): $(IDBLOADER_BIN) $(RK3399_SDK_UEFI_IMG) $(TRUST_IMG)
	@echo "Creating $(TOTAL_SIZE_MB)MB UEFI firmware image..."
	dd if=/dev/zero of=$(UEFI_IMAGE) bs=1M count=$(TOTAL_SIZE_MB) status=progress
	
	@echo "Writing idbloader.bin (loader1, seek=$(LOADER1_START_SECTOR))..."
	dd if=$(IDBLOADER_BIN) of=$(UEFI_IMAGE) seek=$(LOADER1_START_SECTOR) bs=$(SECTOR_SIZE) conv=sync status=progress
	
	@echo "Creating reserved1 partition (zero filled)..."
	dd if=/dev/zero of=$(UEFI_IMAGE) seek=$(RESERVED1_START_SECTOR) bs=$(SECTOR_SIZE) count=$$(($(RESERVED1_END_SECTOR) - $(RESERVED1_START_SECTOR) + 1)) conv=sync status=none
	
	@echo "Creating reserved2 partition (zero filled)..."
	dd if=/dev/zero of=$(UEFI_IMAGE) seek=$(RESERVED2_START_SECTOR) bs=$(SECTOR_SIZE) count=$$(($(RESERVED2_END_SECTOR) - $(RESERVED2_START_SECTOR) + 1)) conv=sync status=none
	
	@echo "Writing RK3399_SDK_UEFI.img (loader2, seek=$(LOADER2_START_SECTOR))..."
	dd if=$(RK3399_SDK_UEFI_IMG) of=$(UEFI_IMAGE) seek=$(LOADER2_START_SECTOR) bs=$(SECTOR_SIZE) conv=sync status=progress
	
	@echo "Writing trust.img (ATF, seek=$(ATF_START_SECTOR))..."
	dd if=$(TRUST_IMG) of=$(UEFI_IMAGE) seek=$(ATF_START_SECTOR) bs=$(SECTOR_SIZE) conv=sync status=progress
	
	@echo "Creating ESP partition (zero filled)..."
	dd if=/dev/zero of=$(UEFI_IMAGE) seek=$(ESP_START_SECTOR) bs=$(SECTOR_SIZE) count=$$(($(ESP_END_SECTOR) - $(ESP_START_SECTOR) + 1)) conv=sync status=none

# Download UEFI files if not present
$(IDBLOADER_BIN):
	$(call download_if_needed,$(IDBLOADER_BIN),$(UEFI_URL_BASE)/$(IDBLOADER_BIN))

$(RK3399_SDK_UEFI_IMG):
	$(call download_if_needed,$(RK3399_SDK_UEFI_IMG),$(UEFI_URL_BASE)/$(RK3399_SDK_UEFI_IMG))

$(TRUST_IMG):
	$(call download_if_needed,$(TRUST_IMG),$(UEFI_URL_BASE)/$(TRUST_IMG))

# Clean generated files
uefi_clean:
	rm -f $(UEFI_IMAGE) $(IDBLOADER_BIN) $(RK3399_SDK_UEFI_IMG) $(TRUST_IMG)