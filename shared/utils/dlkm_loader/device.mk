AB_OTA_PARTITIONS += system_dlkm vendor_dlkm
PRODUCT_PACKAGES += dlkm_loader

# List of modules that should not load automatically
ifeq ($(TARGET_SDCARD_BOOT), true)
PRODUCT_COPY_FILES += \
    device/arduino/imola/shared/utils/dlkm_loader/vendor_ramdisk.modules.blocklist:$(TARGET_COPY_OUT_RAMDISK)/lib/modules/modules.blocklist
else
PRODUCT_COPY_FILES += \
    device/arduino/imola/shared/utils/dlkm_loader/vendor_ramdisk.modules.blocklist:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/lib/modules/modules.blocklist
endif
