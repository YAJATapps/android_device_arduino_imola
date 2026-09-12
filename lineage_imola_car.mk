#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Inherit from device.
$(call inherit-product, device/arduino/imola/device.mk)

PRODUCT_AAPT_PREF_CONFIG := ldpi
PRODUCT_CHARACTERISTICS := automotive,nosdcard

$(call inherit-product, vendor/lineage/config/common_car.mk)

# Device identifier
PRODUCT_NAME := lineage_imola_car
PRODUCT_DEVICE := imola
PRODUCT_BRAND := Arduino
PRODUCT_MODEL := Uno Q
PRODUCT_MANUFACTURER := Arduino

PRODUCT_GMS_CLIENTID_BASE := android-arduino

# Inherit from car
$(call inherit-product, device/google_car/common/pre_google_car.mk)
$(call inherit-product, packages/services/Car/car_product/build/car.mk)
$(call inherit-product, device/google_car/common/post_google_car.mk)
