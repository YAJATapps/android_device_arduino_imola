#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Inherit from device.
$(call inherit-product, device/arduino/imola/device.mk)

PRODUCT_AAPT_PREF_CONFIG := mdpi
PRODUCT_CHARACTERISTICS := automotive,nosdcard

# Inherit Lineage automotive common (overlays, user whitelist)
$(call inherit-product, vendor/lineage/config/common_car.mk)
$(call inherit-product, device/lineage/car/lineage_car_vendor.mk)

# Inherit native AOSP Automotive partition images
$(call inherit-product, packages/services/Car/car_product/build/car_generic_system.mk)
$(call inherit-product, packages/services/Car/car_product/build/car_system_ext.mk)
$(call inherit-product, packages/services/Car/car_product/build/car_product.mk)

SYSTEM_OPTIMIZE_JAVA := false
PRODUCT_BROKEN_SUBOPTIMAL_ORDER_OF_SYSTEM_SERVER_JARS := true
PRODUCT_ENFORCE_RRO_TARGETS :=

# Modern AIDL Automotive HALs
PRODUCT_PACKAGES += \
    android.hardware.broadcastradio-service.default \
    android.hardware.automotive.can-service

# Automotive permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/car_core_hardware.xml:system/etc/permissions/car_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:system/etc/permissions/android.hardware.screen.landscape.xml

# Device identifier
PRODUCT_NAME := lineage_imola_car
PRODUCT_DEVICE := imola
PRODUCT_BRAND := Arduino
PRODUCT_MODEL := Uno Q
PRODUCT_MANUFACTURER := Arduino

PRODUCT_GMS_CLIENTID_BASE := android-arduino
