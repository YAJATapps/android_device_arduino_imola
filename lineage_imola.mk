#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit tablet common Lineage configurations (Wi-Fi only, no telephony/modem)
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)

# Inherit device configuration
$(call inherit-product, device/arduino/imola/device.mk)

# Device identifier
PRODUCT_NAME := lineage_imola
PRODUCT_DEVICE := imola
PRODUCT_BRAND := Arduino
PRODUCT_MODEL := Uno Q
PRODUCT_MANUFACTURER := Arduino

PRODUCT_CHARACTERISTICS := tablet,nosdcard

PRODUCT_GMS_CLIENTID_BASE := android-arduino
