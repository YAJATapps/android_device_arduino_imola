#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_imola.mk \
    $(LOCAL_DIR)/lineage_imola_tv.mk \
    $(LOCAL_DIR)/lineage_imola_car.mk

COMMON_LUNCH_CHOICES := \
    lineage_imola-trunk_staging-user \
    lineage_imola-trunk_staging-userdebug \
    lineage_imola-trunk_staging-eng \
    lineage_imola_tv-trunk_staging-userdebug \
    lineage_imola_car-trunk_staging-userdebug
