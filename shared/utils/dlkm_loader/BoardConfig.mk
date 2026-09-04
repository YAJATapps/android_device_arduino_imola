# system_dlkm partition
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Loadable kernel modules for Arduino Uno Q
include $(DEVICE_PATH)/shared/utils/dlkm_loader/vendor.modules.list.mk
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(VENDOR_DLKM_KERNEL_MODULES_LIST)
