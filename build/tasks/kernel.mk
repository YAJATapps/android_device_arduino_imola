ifneq ($(filter imola, $(TARGET_DEVICE)),)

IMOLA_DTB := $(wildcard $(TARGET_KERNEL_DIR)/qrb2210-arduino-imola.dtb)

ifneq ($(IMOLA_DTB),)
$(PRODUCT_OUT)/dtb.img: $(IMOLA_DTB)
	cat $(IMOLA_DTB) > $@

droidcore: $(PRODUCT_OUT)/dtb.img
endif

endif
