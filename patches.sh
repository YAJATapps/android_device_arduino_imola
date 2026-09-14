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

echo "Patches applied successfully."
