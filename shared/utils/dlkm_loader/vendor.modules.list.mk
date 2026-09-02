VENDOR_DLKM_KERNEL_MODULES_LIST := \
  ath10k_core.ko \
  ath10k_pci.ko \
  ath10k_snoc.ko \
  ath11k_ahb.ko \
  ath11k.ko \
  ath11k_pci.ko \
  ath.ko \
  clk-spmi-pmic-div.ko \
  cqhci.ko \
  gpu-sched.ko \
  lmh.ko \
  lontium-lt9611.ko \
  lontium-lt9611uxc.ko \
  mcp251xfd.ko \
  michael_mic.ko \
  msm.ko \
  nvmem_qfprom.ko \
  qcom-pon.ko \
  qcom_q6v5_mss.ko \
  qcom_q6v5_pas.ko \
  qcom_q6v5_wcss.ko \
  qcom-spmi-adc5.ko \
  qcom-spmi-adc-tm5.ko \
  qcom-spmi-pmic.ko \
  qcom_spmi-regulator.ko \
  qcom-spmi-temp-alarm.ko \
  qcom_tsens.ko \
  reboot-mode.ko \
  sdhci-msm.ko \
  syscon-reboot-mode.ko \
  system_heap.ko \
  videocc-sdm845.ko \
  videocc-sm8250.ko

VENDOR_RAMDISK_KERNEL_MODULES_LIST := \
  apr.ko \
  arm_smmu.ko \
  bam_dma.ko \
  clk-qcom.ko \
  clk-rpmh.ko \
  cmd-db.ko \
  dispcc-sdm845.ko \
  dispcc-sm8250.ko \
  display-connector.ko \
  extcon-usb-gpio.ko \
  fastrpc.ko \
  gcc-sdm845.ko \
  gcc-sm8250.ko \
  gpio-regulator.ko \
  gpio-wcd934x.ko \
  gpucc-sdm845.ko \
  gpucc-sm8250.ko \
  i2c-designware-core.ko \
  i2c-designware-platform.ko \
  i2c-dev.ko \
  i2c-mux.ko \
  i2c-mux-pca954x.ko \
  i2c-qcom-geni.ko \
  i2c-qup.ko \
  i2c-rk3x.ko \
  icc-bcm-voter.ko \
  icc-osm-l3.ko \
  icc-rpmh.ko \
  llcc-qcom.ko \
  lpass-gfm-sm8250.ko \
  mdt_loader.ko \
  mhi.ko \
  msm_serial.ko \
  ohci-hcd.ko \
  ohci-pci.ko \
  ohci-platform.ko \
  pdr_interface.ko \
  phy-qcom-qusb2.ko \
  phy-qcom-snps-femto-v2.ko \
  phy-qcom-usb-hs.ko \
  pinctrl-lpass-lpi.ko \
  pinctrl-msm.ko \
  pinctrl-sdm845.ko \
  pinctrl-sm8250.ko \
  pinctrl-spmi-gpio.ko \
  pinctrl-spmi-mpp.ko \
  pm8916_wdt.ko \
  pm8941-pwrkey.ko \
  q6adm.ko \
  q6afe-clocks.ko \
  q6afe-dai.ko \
  q6afe.ko \
  q6asm-dai.ko \
  q6asm.ko \
  q6core.ko \
  q6routing.ko \
  qcom_aoss.ko \
  qcom-apcs-ipc-mailbox.ko \
  qcom_common.ko \
  qcom-cpufreq-hw.ko \
  qcom_glink.ko \
  qcom_glink_rpm.ko \
  qcom_glink_smem.ko \
  qcom_hwspinlock.ko \
  qcom-ipcc.ko \
  qcom-pdc.ko \
  qcom_pil_info.ko \
  qcom_q6v5_adsp.ko \
  qcom_q6v5.ko \
  qcom_rpmh.ko \
  qcom-rpmh-regulator.ko \
  qcom-scm.ko \
  qcom_smd.ko \
  qcom_sysmon.ko \
  qcom_usb_vbus-regulator.ko \
  qcom-vadc-common.ko \
  qcom-wdt.ko \
  qmi_helpers.ko \
  qnoc-sdm845.ko \
  qnoc-sm8250.ko \
  qrtr.ko \
  qrtr-mhi.ko \
  qrtr-smd.ko \
  qrtr-tun.ko \
  regmap-sdw.ko \
  regmap-slimbus.ko \
  reset-qcom-aoss.ko \
  reset-qcom-pdc.ko \
  rmtfs_mem.ko \
  rpmhpd.ko \
  rpmsg_ns.ko \
  rtc-pm8xxx.ko \
  slim-qcom-ngd-ctrl.ko \
  slimbus.ko \
  smem.ko \
  smp2p.ko \
  smsm.ko \
  snd-soc-dmic.ko \
  snd-soc-hdmi-codec.ko \
  snd-soc-lpass-va-macro.ko \
  snd-soc-lpass-wsa-macro.ko \
  snd-soc-max98927.ko \
  snd-soc-qcom-common.ko \
  snd-soc-rl6231.ko \
  snd-soc-rt5663.ko \
  snd-soc-sdm845.ko \
  snd-soc-sm8250.ko \
  snd-soc-wcd9335.ko \
  snd-soc-wcd934x.ko \
  snd-soc-wcd-mbhc.ko \
  snd-soc-wsa881x.ko \
  socinfo.ko \
  soundwire-bus.ko \
  soundwire-qcom.ko \
  spmi-pmic-arb.ko \
  spi-geni-qcom.ko \
  spi-pl022.ko \
  spi-qcom-qspi.ko \
  spi-qup.ko \
  ulpi.ko \
  wcd934x.ko

ifeq ($(TARGET_KERNEL_USE),5.15)
VENDOR_DLKM_KERNEL_MODULES_LIST += \
  qcom-pmic-typec.ko

VENDOR_RAMDISK_KERNEL_MODULES_LIST += \
  phy-qcom-qmp.ko \
  q6dsp-common.ko \
  ufs_qcom.ko
endif

ifeq ($(TARGET_KERNEL_USE),6.1)
VENDOR_DLKM_KERNEL_MODULES_LIST += \
  leds-qcom-lpg.ko \
  qcom-pmic-typec.ko \
  qnoc-sm8450.ko

VENDOR_RAMDISK_KERNEL_MODULES_LIST += \
  cpr.ko \
  drm_display_helper.ko \
  drm_dp_aux_bus.ko \
  gcc-sm8450.ko \
  gpi.ko \
  phy-qcom-qmp-combo.ko \
  phy-qcom-qmp-pcie.ko \
  phy-qcom-qmp-pcie-msm8996.ko \
  phy-qcom-qmp-ufs.ko \
  phy-qcom-qmp-usb.ko \
  pinctrl-sm8250-lpass-lpi.ko \
  pinctrl-sm8450.ko \
  q6apm-dai.ko \
  q6apm-lpass-dais.ko \
  q6prm-clocks.ko \
  q6prm.ko \
  snd-q6apm.ko \
  snd-q6dsp-common.ko \
  snd-soc-lpass-macro-common.ko \
  snd-soc-qcom-sdw.ko \
  spm.ko \
  ufs_qcom.ko
endif

ifeq ($(TARGET_KERNEL_USE),6.6)
VENDOR_DLKM_KERNEL_MODULES_LIST += \
  leds-qcom-lpg.ko \
  qcom_pmic_tcpm.ko \
  qnoc-sm8450.ko

VENDOR_RAMDISK_KERNEL_MODULES_LIST += \
  cpr.ko \
  drm_display_helper.ko \
  drm_dp_aux_bus.ko \
  gcc-sm8450.ko \
  gpi.ko \
  phy-qcom-qmp-combo.ko \
  phy-qcom-qmp-pcie.ko \
  phy-qcom-qmp-pcie-msm8996.ko \
  phy-qcom-qmp-ufs.ko \
  phy-qcom-qmp-usb.ko \
  pinctrl-sm8250-lpass-lpi.ko \
  pinctrl-sm8450.ko \
  q6apm-dai.ko \
  q6apm-lpass-dais.ko \
  q6prm-clocks.ko \
  q6prm.ko \
  qcom_ice.ko \
  snd-q6apm.ko \
  snd-q6dsp-common.ko \
  snd-soc-lpass-macro-common.ko \
  snd-soc-qcom-sdw.ko \
  snd-soc-wcd-classh.ko \
  spm.ko \
  ufs-qcom.ko
endif
