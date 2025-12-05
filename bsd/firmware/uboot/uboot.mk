UBOOT_TARGET = u-boot-rock-pi-n10
UBOOT_URL_BASE = https://personalbsd.org/download/u-boot/$(UBOOT_TARGET)
IDBLOADER_IMG = idbloader.img
UBOOT_ITB = u-boot.itb
IMAGE_SIZE_MB = 64
UBOOT_IMAGE = $(UBOOT_TARGET).img

FILE_EXISTS = test -f $1

define download_if_needed
	@if $(call FILE_EXISTS,$(1)); then \
		echo "$(1) Exists"; \
	else \
		echo "Downloading $(1)..."; \
		wget -q --show-progress $(2) -O $(1); \
	fi
endef

.PHONY: uboot_image
uboot_image: $(UBOOT_IMAGE)
	@echo "U-boot image: $(UBOOT_IMAGE)"

$(UBOOT_IMAGE): $(IDBLOADER_IMG) $(UBOOT_ITB)
	@echo "Creating $(IMAGE_SIZE_MB)MB empty image..."
	dd if=/dev/zero of=$(UBOOT_IMAGE) bs=1M count=$(IMAGE_SIZE_MB) status=progress

	@echo "Writing idbloader.img (seek=64, bs=512)..."
	dd if=$(IDBLOADER_IMG) of=$(UBOOT_IMAGE) seek=64 bs=512 conv=sync status=progress

	@echo "Writing u-boot.itb (seek=16384, bs=512)..."
	dd if=$(UBOOT_ITB) of=$(UBOOT_IMAGE) seek=16384 bs=512 conv=sync status=progress

	@echo "Image:"
	ls -lh $(UBOOT_IMAGE)

$(IDBLOADER_IMG):
	$(call download_if_needed,$(IDBLOADER_IMG),$(UBOOT_URL_BASE)/$(IDBLOADER_IMG))

$(UBOOT_ITB):
	$(call download_if_needed,$(UBOOT_ITB),$(UBOOT_URL_BASE)/$(UBOOT_ITB))

# Clean generated files
uboot_clean:
	rm -f $(UBOOT_IMAGE) $(IDBLOADER_IMG) $(UBOOT_ITB)