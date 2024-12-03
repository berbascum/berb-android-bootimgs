#!/bin/bash

## Berbascum 2024

TARGET_OS="droidian"
ARCH_TARGET="arm64"
SUITE_INITRAM="s100"
# KERNEL_RELEASE="${TARGET_OS}3-rc4"

## initram skels:
# Plymouth messages are only working on the bookworm based skells
INITRAM_SKEL_URL="https://github.com/droidian-berb/initramfs-droidian-skels/raw/refs/heads/droidian"
# INITRAM_SKEL_IMG="initramfs.img-droidian-snap100-arm64-yk-nominienv_skel_v20241202"
INITRAM_SKEL_IMG="initramfs-droidian-bookworm-nominienv-arm64-skel_v2"
#INITRAM_SKEL_IMG="initramfs.img-droidian-squeeze-arm64-minienv_skel_v20241203"
INITRAM_BOOTSCRIPTS_URL="https://github.com/droidian-berb/initramfs-droidian-boot-scripts"
INITRAM_BOOTSCRIPTS_BRANCH="sid"

#TOOLS_DIR="tools"

## Image configuration values
PAGE_SIZE="4096"
BASE_OFFSET="0x00000000"
KERNEL_OFFSET="0x00008000"
DTB_OFFSET="0x00f00000"
INITRAMFS_OFFSET="0x01000000"
SECONDIMAGE_OFFSET="0x00f00000"
TAGS_OFFSET="0x00000100"
KERNEL_BOOTIMAGE_VERSION="2"
OS_PATCH_LVL="2022-01-01"

## kernel cmdline options
KERNEL_BOOTIMAGE_CMDLINE="androidboot.hardware=qcom androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 console=tty0 earlycon=msm_geni_serial,0x4a90000 androidboot.memcg=1 buildvariant=userdebug systemd.unified_cgroup_hierarchy=0 droidian.lvm.noresize luks.cust.dev=/dev/mmcblk0p4 droidian.lvm.prefer"

# halium.recovery
# skip_initramfs -> cmdline (scripts/halium)
