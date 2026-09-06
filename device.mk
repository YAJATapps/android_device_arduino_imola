#
# Copyright (C) 2026 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DEVICE_PATH := device/arduino/imola

# Dalvik VM heap
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

# Virtual A/B OTA
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# Dynamic partitions
PRODUCT_BUILD_SUPER_PARTITION := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true

# AB OTA Partitions
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    product \
    system \
    system_ext \
    vendor

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH) \
    hardware/qcom/wlan

# DLKM Loader
include $(DEVICE_PATH)/shared/utils/dlkm_loader/device.mk
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/shared/utils/dlkm_loader/dlkm_loader.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/dlkm_loader.rc

# BootControl HAL & VINTF
PRODUCT_PACKAGES += \
    com.android.hardware.boot \
    android.hardware.boot-service.default_recovery \
    vendor_compatibility_matrix.xml

# Power, Health, and Thermal AIDL HALs
PRODUCT_PACKAGES += \
    android.hardware.health-service.example \
    android.hardware.health-service.example_recovery \
    android.hardware.power-service.example \
    android.hardware.power.stats-service.example \
    com.android.hardware.thermal

# Security HALs (KeyMint & Gatekeeper software implementations)
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service \
    com.android.hardware.gatekeeper.nonsecure

# USB Host & AIDL HAL
PRODUCT_PACKAGES += \
    android.hardware.usb-service.example

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

# Bluetooth utilities
PRODUCT_PACKAGES += bdaddr
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/shared/utils/bdaddr/set_bdaddr.sh:$(TARGET_COPY_OUT_VENDOR)/bin/set_bdaddr.sh \
    $(DEVICE_PATH)/product.prop:$(TARGET_COPY_OUT_PRODUCT)/build.prop

# Hardware scripts
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/shared/utils/set_hw.sh:$(TARGET_COPY_OUT_VENDOR)/bin/set_hw.sh \
    $(DEVICE_PATH)/shared/utils/set_udc.sh:$(TARGET_COPY_OUT_VENDOR)/bin/set_udc.sh

# Init scripts & configs
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init.imola.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.imola.rc \
    $(DEVICE_PATH)/init.imola.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.imola.usb.rc \
    $(DEVICE_PATH)/ueventd.imola.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc \
    $(DEVICE_PATH)/cgroups.json:$(TARGET_COPY_OUT_VENDOR)/etc/cgroups.json \
    $(DEVICE_PATH)/fstab.imola:$(TARGET_COPY_OUT_RAMDISK)/first_stage_ramdisk/fstab.imola \
    $(DEVICE_PATH)/fstab.imola:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.imola \
    frameworks/base/data/keyboards/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/imola.kl

# Audio HAL (AIDL) & Media configs
PRODUCT_PACKAGES += \
    com.android.hardware.audio

$(call inherit-product, hardware/interfaces/audio/aidl/default/audio_effects.mk)

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    $(DEVICE_PATH)/etc/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(DEVICE_PATH)/etc/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles.xml

# Graphics (drm_hwcomposer + swangle + minigbm)
include $(DEVICE_PATH)/shared/graphics/drm_hwcomposer/device.mk
include $(DEVICE_PATH)/shared/graphics/swangle/device.mk
include $(DEVICE_PATH)/shared/graphics/minigbm_msm/device.mk

# Properties
PRODUCT_VENDOR_PROPERTIES += \
    ro.soc.manufacturer=Qualcomm \
    ro.soc.model=QRB2210 \
    persist.sys.zram_enabled=1 \
    debug.stagefright.c2inputsurface=-1

# TODO: Remove before release (skips ~50s on-device dex2oat on fresh flash)
PRODUCT_VENDOR_PROPERTIES += \
    dalvik.vm.disable-odrefresh=true

# Enable ADB by default (TCP 5555 for network ADB; USB operates in host mode)
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=none \
    service.adb.tcp.port=5555 \
    ro.adb.secure=0

PRODUCT_SHIPPING_API_LEVEL := 36
TARGET_HARDWARE := imola

# VINTF Kernel Requirements (permit 6.18 kernel on Android 16)
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Inherit from vendor blobs if available
$(call inherit-product-if-exists, vendor/arduino/imola/imola-vendor.mk)
