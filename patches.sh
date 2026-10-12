#!/bin/bash
set -e

# Determine Android build root
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TOP="${ANDROID_BUILD_TOP:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

# external/dng_sdk
if [ -f "$TOP/external/dng_sdk/Android.bp" ]; then
    echo "Patching external/dng_sdk: removing vendor_available..."
    sed -i '/vendor_available: true,/d' "$TOP/external/dng_sdk/Android.bp"
fi

# external/libjxl
if [ -f "$TOP/external/libjxl/Android.bp" ]; then
    echo "Patching external/libjxl: removing vendor_available..."
    sed -i '/vendor_available: true,/d' "$TOP/external/libjxl/Android.bp"
fi

# device/lineage/sepolicy
if [ -f "$TOP/device/lineage/sepolicy/atv/vendor/gmscore_app.te" ]; then
    echo "Patching device/lineage/sepolicy: disabling apk_verity_prop for gmscore_app..."
    sed -i 's/^get_prop(gmscore_app, apk_verity_prop)/#get_prop(gmscore_app, apk_verity_prop)/' "$TOP/device/lineage/sepolicy/atv/vendor/gmscore_app.te"
fi

# packages/apps/SetupWizard
if [ -f "$TOP/packages/apps/SetupWizard/app/src/main/java/org/lineageos/setupwizard/WelcomeActivity.kt" ]; then
    echo "Patching packages/apps/SetupWizard: enabling skip on boot (Kotlin)..."
    sed -i 's/get() = Build.TYPE == "eng"/get() = true/' "$TOP/packages/apps/SetupWizard/app/src/main/java/org/lineageos/setupwizard/WelcomeActivity.kt"
elif [ -f "$TOP/packages/apps/SetupWizard/src/org/lineageos/setupwizard/WelcomeActivity.java" ]; then
    echo "Patching packages/apps/SetupWizard: auto-finishing setup on boot..."
    sed -i 's/if (Build.TYPE.equals("eng"))/SetupWizardUtils.finishSetupWizard(this); if (false)/' "$TOP/packages/apps/SetupWizard/src/org/lineageos/setupwizard/WelcomeActivity.java"
fi

# system/vold: C++23 missing <algorithm> header for std::replace
VOLD_PUBLIC_VOL="$TOP/system/vold/model/PublicVolume.cpp"
if [ -f "$VOLD_PUBLIC_VOL" ] && ! grep -q "#include <algorithm>" "$VOLD_PUBLIC_VOL"; then
    echo "Patching system/vold: adding missing <algorithm> header for C++23..."
    sed -i '/#include "PublicVolume.h"/a #include <algorithm>' "$VOLD_PUBLIC_VOL"
fi

# bootable/recovery: C++23 missing <algorithm> and <vector> headers
RECOVERY_PUBLIC_VOL="$TOP/bootable/recovery/volume_manager/PublicVolume.cpp"
if [ -f "$RECOVERY_PUBLIC_VOL" ] && ! grep -q "#include <algorithm>" "$RECOVERY_PUBLIC_VOL"; then
    echo "Patching bootable/recovery: adding missing <algorithm> header for C++23..."
    sed -i '/#include "PublicVolume.h"/a #include <algorithm>' "$RECOVERY_PUBLIC_VOL"
fi

RECOVERY_VOL_MGR="$TOP/bootable/recovery/volume_manager/include/volume_manager/VolumeManager.h"
if [ -f "$RECOVERY_VOL_MGR" ] && ! grep -q "#include <vector>" "$RECOVERY_VOL_MGR"; then
    echo "Patching bootable/recovery: adding missing <vector> header for C++23..."
    sed -i '/#include <string>/a #include <vector>' "$RECOVERY_VOL_MGR"
fi

# frameworks/base: NotificationAttentionHelper NPE when mLineageNotificationLights is null
NMS_ATTENTION_HELPER="$TOP/frameworks/base/services/core/java/com/android/server/notification/NotificationAttentionHelper.java"
if [ -f "$NMS_ATTENTION_HELPER" ] && ! grep -q "mLineageNotificationLights != null && !mLineageNotificationLights.showLightsScreenOn()" "$NMS_ATTENTION_HELPER"; then
    echo "Patching frameworks/base: fixing mLineageNotificationLights NPE in NotificationAttentionHelper..."
    sed -i 's/if (!mLineageNotificationLights\.showLightsScreenOn())/if (mLineageNotificationLights != null \&\& !mLineageNotificationLights.showLightsScreenOn())/g' "$NMS_ATTENTION_HELPER"
fi

echo "Patches applied successfully."

