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

# which will be used by the minigbm allocator compilation
$(call soong_config_set,minigbm,platform,msm)

PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    mapper.minigbm \
    gralloc.minigbm

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware.gralloc=minigbm

# QCM2290/QRB2210 DPU lacks a hardware UBWC decoder on display planes (has_no_ubwc = true).
# Display buffers must be uncompressed (linear) for DRM/KMS scanout.
PRODUCT_VENDOR_PROPERTIES += \
    vendor.minigbm.debug=nocompression

