#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

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

PRODUCT_GMS_CLIENTID_BASE := android-arduino
