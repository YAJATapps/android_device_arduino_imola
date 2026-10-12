#!/bin/bash
set -e

# Determine Android build root
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TOP="${ANDROID_BUILD_TOP:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

# external/dng_sdk and external/libjxl vendor_available are officially supported in Lineage 24

# device/lineage/sepolicy
if [ -f "$TOP/device/lineage/sepolicy/atv/vendor/gmscore_app.te" ]; then
    echo "Patching device/lineage/sepolicy: disabling apk_verity_prop for gmscore_app..."
    sed -i 's/^get_prop(gmscore_app, apk_verity_prop)/#get_prop(gmscore_app, apk_verity_prop)/' "$TOP/device/lineage/sepolicy/atv/vendor/gmscore_app.te"
fi

# packages/apps/SetupWizard
if [ -f "$TOP/packages/apps/SetupWizard/app/src/main/java/org/lineageos/setupwizard/WelcomeActivity.kt" ]; then
    echo "Patching packages/apps/SetupWizard: auto-finishing setup on boot (Kotlin)..."
    sed -i 's/get() = Build.TYPE == "eng"/get() = true/' "$TOP/packages/apps/SetupWizard/app/src/main/java/org/lineageos/setupwizard/WelcomeActivity.kt"
elif [ -f "$TOP/packages/apps/SetupWizard/src/org/lineageos/setupwizard/WelcomeActivity.java" ]; then
    echo "Patching packages/apps/SetupWizard: auto-finishing setup on boot..."
    sed -i 's/if (Build.TYPE.equals("eng"))/SetupWizardUtils.finishSetupWizard(this); if (false)/' "$TOP/packages/apps/SetupWizard/src/org/lineageos/setupwizard/WelcomeActivity.java"
fi

echo "Patches applied successfully."
