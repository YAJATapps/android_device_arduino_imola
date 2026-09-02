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

ifeq ($(TARGET_BOARD_PLATFORM), imola)

LOCAL_PATH := $(call my-dir)

$(eval $(call declare-1p-copy-files,device/arduino/imola,.conf))
$(eval $(call declare-1p-copy-files,device/arduino/imola,.kl))
$(eval $(call declare-1p-copy-files,device/arduino/imola,.policy))
$(eval $(call declare-1p-copy-files,device/arduino/imola,.rc))
$(eval $(call declare-1p-copy-files,device/arduino/imola,.sh))
$(eval $(call declare-1p-copy-files,device/arduino/imola,.xml))
$(eval $(call declare-1p-copy-files,device/arduino/imola,fstab.imola))

include $(call all-makefiles-under,$(LOCAL_PATH))
endif
