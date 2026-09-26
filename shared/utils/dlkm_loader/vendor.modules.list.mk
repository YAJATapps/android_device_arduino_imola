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
    apr.ko \
    ath.ko \
    ath10k_core.ko \
    ath10k_snoc.ko \
    bluetooth.ko \
    bnep.ko \
    br_netfilter.ko \
    bridge.ko \
    btbcm.ko \
    btqca.ko \
    cdc_ether.ko \
    cdc_ncm.ko \
    cfg80211.ko \
    ecc.ko \
    ecdh_generic.ko \
    hci_uart.ko \
    icc-bwmon.ko \
    joydev.ko \
    libarc4.ko \
    libdes.ko \
    llc.ko \
    lmh.ko \
    mac80211.ko \
    mc.ko \
    mcp251xfd.ko \
    onboard_usb_dev.ko \
    overlay.ko \
    pdr_interface.ko \
    pinctrl-lpass-lpi.ko \
    pinctrl-sm6115-lpass-lpi.ko \
    pwrseq-core.ko \
    qcom-pon.ko \
    qcom-rng.ko \
    qcom-spmi-adc5.ko \
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
    slimbus.ko \
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
    usbnet.ko \
    v4l2-mem2mem.ko \
    venus-core.ko \
    venus-dec.ko \
    videobuf2-common.ko \
    videobuf2-dma-contig.ko \
    videobuf2-memops.ko \
    videobuf2-v4l2.ko \
    videodev.ko

