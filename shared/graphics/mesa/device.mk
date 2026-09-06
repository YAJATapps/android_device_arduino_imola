#
# Copyright (C) 2014 The Android Open-Source Project
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

# Out-of-tree Mesa (Freedreno / Turnip) graphics configuration
# Prebuilt libraries dropped into vendor/arduino/imola/proprietary/vendor/

# Hardware EGL and Vulkan properties
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160 \
    ro.hardware.egl=mesa \
    ro.opengles.version=196608 \
    persist.demo.rotationlock=1

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.vulkan=freedreno \
    debug.hwui.renderer=skiagl

# Vulkan & GLES permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2022-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

TARGET_VULKAN_SUPPORT := true
TARGET_USES_VULKAN := true

# Automatically copy any out-of-tree Mesa prebuilt libraries dropped into vendor
MESA_PREBUILT_PATH := vendor/arduino/imola/proprietary/vendor

$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib64/egl/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib64/egl/$(notdir $(f))))
$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib64/hw/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib64/hw/$(notdir $(f))))
$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib64/dri/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib64/dri/$(notdir $(f))))
$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib64/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib64/$(notdir $(f))))

$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib/egl/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib/egl/$(notdir $(f))))
$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib/hw/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib/hw/$(notdir $(f))))
$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib/dri/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib/dri/$(notdir $(f))))
$(foreach f,$(wildcard $(MESA_PREBUILT_PATH)/lib/*.so), \
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_VENDOR)/lib/$(notdir $(f))))
