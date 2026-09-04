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

# Curated kernel modules list for Arduino Uno Q (imola, Qualcomm QRB2210/QCM2290)
# Derived from live hardware stock module footprint (/nfs/general/uno/lsmod_stock.log)

VENDOR_DLKM_KERNEL_MODULES_LIST := \
    af_alg.ko \
    anx7625.ko \
    apr.ko \
    ath.ko \
    ath10k_core.ko \
    ath10k_snoc.ko \
    backlight.ko \
    bluetooth.ko \
    bnep.ko \
    br_netfilter.ko \
    bridge.ko \
    btbcm.ko \
    btqca.ko \
    cdc_ether.ko \
    cdc_ncm.ko \
    cec.ko \
    cfg80211.ko \
    dispcc-qcm2290.ko \
    drm.ko \
    drm_client_lib.ko \
    drm_display_helper.ko \
    drm_dp_aux_bus.ko \
    drm_exec.ko \
    drm_kms_helper.ko \
    ecc.ko \
    ecdh_generic.ko \
    gpi.ko \
    gpu-sched.ko \
    gpucc-qcm2290.ko \
    hci_uart.ko \
    i2c-qcom-geni.ko \
    icc-bwmon.ko \
    joydev.ko \
    libarc4.ko \
    libdes.ko \
    llc.ko \
    llcc-qcom.ko \
    lmh.ko \
    mac80211.ko \
    mc.ko \
    mcp251xfd.ko \
    mdt_loader.ko \
    msm.ko \
    ocmem.ko \
    onboard_usb_dev.ko \
    overlay.ko \
    pdr_interface.ko \
    phy-qcom-qmp-usbc.ko \
    phy-qcom-qusb2.ko \
    pinctrl-lpass-lpi.ko \
    pinctrl-sm6115-lpass-lpi.ko \
    pwrseq-core.ko \
    qcom-pon.ko \
    qcom-rng.ko \
    qcom-spmi-adc5.ko \
    qcom-spmi-temp-alarm.ko \
    qcom-wdt.ko \
    qcom_common.ko \
    qcom_glink_smem.ko \
    qcom_pd_mapper.ko \
    qcom_pdr_msg.ko \
    qcom_pil_info.ko \
    qcom_q6v5.ko \
    qcom_q6v5_pas.ko \
    qcom_stats.ko \
    qcom_sysmon.ko \
    qcom_usb_vbus-regulator.ko \
    qcrypto.ko \
    qmi_helpers.ko \
    qrtr-smd.ko \
    qrtr.ko \
    regmap-sdw.ko \
    rfcomm.ko \
    rfkill.ko \
    rmtfs_mem.ko \
    rpmsg_char.ko \
    rpmsg_ctrl.ko \
    rtc-pm8xxx.ko \
    slimbus.ko \
    snd-soc-hdmi-codec.ko \
    snd-soc-lpass-macro-common.ko \
    snd-soc-lpass-rx-macro.ko \
    snd-soc-lpass-tx-macro.ko \
    snd-soc-lpass-va-macro.ko \
    snd-soc-pm4125-sdw.ko \
    snd-soc-pm4125.ko \
    snd-soc-qcom-common.ko \
    snd-soc-qcom-sdw.ko \
    snd-soc-sm8250.ko \
    snd-soc-wcd-mbhc.ko \
    socinfo.ko \
    soundwire-bus.ko \
    soundwire-qcom.ko \
    spi-geni-qcom.ko \
    spidev.ko \
    stp.ko \
    typec.ko \
    usbnet.ko \
    v4l2-mem2mem.ko \
    venus-core.ko \
    venus-dec.ko \
    videobuf2-common.ko \
    videobuf2-dma-contig.ko \
    videobuf2-memops.ko \
    videobuf2-v4l2.ko \
    videodev.ko \
    xt_MASQUERADE.ko \
    xt_addrtype.ko
