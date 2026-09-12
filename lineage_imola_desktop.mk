#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit tablet common Lineage configurations (large screen / desktop base)
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)

# Inherit device configuration
$(call inherit-product, device/arduino/imola/device.mk)

# Desktop characteristics and display config
PRODUCT_CHARACTERISTICS := desktop
PRODUCT_AAPT_PREF_CONFIG := mdpi

# PC core hardware features (freeform windowing, PC hardware type)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/pc_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/pc_core_hardware.xml

# Enable native Android Desktop Windowing & Freeform window management
PRODUCT_PRODUCT_PROPERTIES += \
    persist.wm.debug.desktop_mode=2 \
    persist.wm.debug.desktop_mode_compat=1 \
    persist.sys.freeform_window_management=1 \
    ro.config.desktop_mode=true

# Device identifier
PRODUCT_NAME := lineage_imola_desktop
PRODUCT_DEVICE := imola
PRODUCT_BRAND := Arduino
PRODUCT_MODEL := Uno Q
PRODUCT_MANUFACTURER := Arduino

PRODUCT_GMS_CLIENTID_BASE := android-arduino
