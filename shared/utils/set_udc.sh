#! /vendor/bin/sh
# Grep and set the vendor.usb.controller property from
# /sys/class/udc at the boot time.
#
# Upstream commit eb9b7bfd5954 ("arm64: dts: qcom: Harmonize DWC
# USB3 DT nodes name") (v5.14-rc1) changed the DTS USB node names,
# breaking the sys.usb.controller property hardcoded in the
# platform specific init.usb.common.rc
#
# This script will get rid of the static/hardcoded property name
# which we set in init.<hw>.usb.rc and set it to the available
# on-board USB controller from /sys/class/udc instead.

# Auto-detect the on-board UDC controller from /sys/class/udc
UDC=$(ls /sys/class/udc/ 2>/dev/null | head -n 1)
if [ -n "${UDC}" ]; then
    setprop vendor.usb.controller "${UDC}"
fi
