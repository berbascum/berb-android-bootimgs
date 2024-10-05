#!/bin/bash

## Berbascum 2024

## Image configuration values
PAGE_SIZE="4096"
BASE_OFFSET="0x00000000"
KERNEL_OFFSET="0x00008000"
DTB_OFFSET="0x00f00000"
INITRAMFS_OFFSET="0x01000000"
SECONDIMAGE_OFFSET="0x00f00000"
TAGS_OFFSET="0x00000100"
KERNEL_BOOTIMAGE_VERSION="2"
OS_PATCH_LVL="2021-10-01"
## kernel cmdline options
#KERNEL_BOOTIMAGE_CMDLINE="androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:1280x720,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 console=tty0 droidian.lvm.prefer droidian.yubikey halium.recovery"
KERNEL_BOOTIMAGE_CMDLINE="androidboot.hardware=qcom androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 console=tty0 earlycon=msm_geni_serial,0x4a90000 androidboot.memcg=1 buildvariant=userdebug systemd.unified_cgroup_hierarchy=0 droidian.lvm.noresize luks.cust.dev=/dev/mmcblk0p4 droidian.lvm.prefer"
#KERNEL_BOOTIMAGE_CMDLINE="androidboot.hardware=qcom androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 console=tty0 console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0x4a90000 androidboot.memcg=1 buildvariant=userdebug systemd.unified_cgroup_hierarchy=0 droidian.lvm.noresize luks.cust.dev=/dev/mmcblk0p4"

# skip_initramfs -> cmdline (scripts/halium)
