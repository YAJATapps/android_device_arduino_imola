#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_imola.mk \
    $(LOCAL_DIR)/lineage_imola_tv.mk \
    $(LOCAL_DIR)/lineage_imola_car.mk

COMMON_LUNCH_CHOICES := \
    lineage_imola-cp2a-user \
    lineage_imola-cp2a-userdebug \
    lineage_imola-cp2a-eng \
    lineage_imola_tv-cp2a-userdebug \
    lineage_imola_car-cp2a-userdebug
