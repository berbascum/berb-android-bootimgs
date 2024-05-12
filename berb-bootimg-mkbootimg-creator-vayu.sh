#!/bin/bash

## Berbascum 2024  v1.0.0-1
 # Create boot.img_post_build with files in kernel output dir

# Requeriments
  # apt-get install mkbootimg
  # Some vars need to be defined with specific information
    # KERNEL_SOURCES_PATH need to be defined with own kernel sources root_dir
    # VAR KERNEL_BOOTIMAGE_CMDLINE need to be defined with device specific values
    # VARS in "Image configuration values" need to be defined with device specific values


if [ -e "./bzImage" ]; then
    kernel="bzImage"
elif [ -e "./kernel" ]; then
    kernel="kernel"
fi
if [ -e "./initramfs" ]; then
    initrd="initramfs"
elif [ -e "./ramdisk.cpio" ]; then
    initrd="ramdisk.cpio"
fi
if [ -e "./dtb" ]; then
    dtb="dtb"
fi


## Global vars
fn_vars_set_img_conf() {
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
	KERNEL_BOOTIMAGE_CMDLINE="androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 console=tty0 droidian.lvm.prefer droidian.yubikey"
	## Arguments definition for mkbootimg
        ## kernel
	MKBOOTIMG_KERNEL_ARG="--kernel ${kernel}"
	MKBOOTIMG_KERNEL_OFFSET_ARG="--kernel_offset $KERNEL_OFFSET"
	MKBOOTIMG_TAGS_OFFSET_ARG="--tags_offset $TAGS_OFFSET"
        MKBOOTIMG_OS_PATCH_LVL_ARG="--os_patch_level ${OS_PATCH_LVL}"
        ## dtb
	MKBOOTIMG_DTB_ARG="--dtb ${dtb}"
	MKBOOTIMG_DTB_OFFSET_ARG="--dtb_offset $DTB_OFFSET"
        ## ramdisk
	MKBOOTIMG_RAMDISK_ARG="--ramdisk ${initrd}"
	MKBOOTIMG_RAMDISK_OFFSET_ARG="--ramdisk_offset $INITRAMFS_OFFSET"
        ## other offssets
	MKBOOTIMG_BASE_ARG="--base $BASE_OFFSET"
	MKBOOTIMG_PAGESIZE_ARG="--pagesize $PAGE_SIZE"
	MKBOOTIMG_SECOND_OFFSET_ARG="--second_offset $SECONDIMAGE_OFFSET"
        ## Boot config
	MKBOOTIMG_CMDLINE_ARG="--cmdline \"$KERNEL_BOOTIMAGE_CMDLINE\""
	MKBOOTIMG_HEADER_VER_ARG="--header_version $KERNEL_BOOTIMAGE_VERSION"
	MKBOOTIMG_OUT_IMG="-o ./boot-berb-mkboot.img"
}	## END fn_vars_set_img_conf

fn_mkbootimg() {
	## Image creation
	eval mkbootimg \
		${MKBOOTIMG_KERNEL_ARG} \
		${MKBOOTIMG_DTB_ARG} \
		${MKBOOTIMG_RAMDISK_ARG} \
		${MKBOOTIMG_BASE_ARG} \
		${MKBOOTIMG_KERNEL_OFFSET_ARG} \
		${MKBOOTIMG_RAMDISK_OFFSET_ARG} \
		${MKBOOTIMG_SECOND_OFFSET_ARG} \
		${MKBOOTIMG_TAGS_OFFSET_ARG} \
		${MKBOOTIMG_PAGESIZE_ARG} \
		${MKBOOTIMG_CMDLINE_ARG} \
		${MKBOOTIMG_HEADER_VER_ARG} \
		${MKBOOTIMG_OS_PATCH_LVL_ARG} \
		${MKBOOTIMG_OUT_IMG}

}	# END fn_mkbootimg


## Script execution
fn_vars_set_img_conf
fn_mkbootimg
