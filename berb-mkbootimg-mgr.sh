#!/bin/bash

## Script in bash to update and rebuild android based bootimages using mkbootimg as backend
#
## Version 1.0.0.1
## Working initial initram-upgrade-bootpart command
#
# Upstream-Name: berb-android-mkbootimg-mgr
# Source: https://github.com/berbascum/berb-android-mkbootimg-mgr
#
# Copyright (C) 2024 Berbascum <berbascum@ticv.cat>
# All rights reserved.
#
# BSD 3-Clause License
#
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the <organization> nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



# Requeriments
  # apt-get install mkbootimg  ## Tested with the Debiann bookworm and trixie apt versions

START_DIR=$(pwd)

abort() {
    echo
    echo "$*"
    exit 1
}
message() {
    echo
    echo "$*"
}

## DEVICE_TARGET required
DEVICE_TARGET="$1"
if [ -z "${DEVICE_TARGET}" ]; then
   abort "A device target name is required as 1st script arg"
else
    echo "Device selected: $1"
fi

## Device mkbootimg config file required
[ -e "./mkbootimg-config-${DEVICE_TARGET}.sh" ] ||  abort "Device config file missing"
source ./mkbootimg-config-${DEVICE_TARGET}.sh

## Set action var
action="$2"

fn_bootimage_get_from_part() {
    BOOTIMG_FILES_DIR="$(mktemp -d)"
    ## Get the image from the boot partition
    BOOT_PART="/dev/disk/by-partlabel/boot"
    if [ -e "${BOOT_PART}" ]; then
        sudo dd if="${BOOT_PART}" of=${BOOTIMG_FILES_DIR}/boot.img
        sudo chown $(whoami): ${BOOTIMG_FILES_DIR}/boot.img
    else
        echo "Boot part \"${BOOT_PART}\" not exist"
        exit 1
    fi
    cd ${BOOTIMG_FILES_DIR}
    unpack_bootimg --boot_img boot.img --out ./ > boot.cfg
    KERNEL_BOOTIMAGE_CMDLINE="$( grep "command line args"  boot.cfg | awk -F': ' '{print $2}')"
}

fn_mkboot_image_config() {
    ## Arguments definition for mkbootimg
    ## Paths
    ## kernel
    MKBOOTIMG_KERNEL_ARG="--kernel ${BOOTIMG_FILES_DIR}/kernel"
    MKBOOTIMG_KERNEL_OFFSET_ARG="--kernel_offset $KERNEL_OFFSET"
    MKBOOTIMG_TAGS_OFFSET_ARG="--tags_offset $TAGS_OFFSET"
    MKBOOTIMG_OS_PATCH_LVL_ARG="--os_patch_level ${OS_PATCH_LVL}"
    ## dtb
    MKBOOTIMG_DTB_ARG="--dtb ${BOOTIMG_FILES_DIR}/dtb"
    MKBOOTIMG_DTB_OFFSET_ARG="--dtb_offset $DTB_OFFSET"
    ## ramdisk
    MKBOOTIMG_RAMDISK_ARG="--ramdisk ${BOOTIMG_FILES_DIR}/ramdisk"
    MKBOOTIMG_RAMDISK_OFFSET_ARG="--ramdisk_offset $INITRAMFS_OFFSET"
    ## other offssets
    MKBOOTIMG_BASE_ARG="--base $BASE_OFFSET"
    MKBOOTIMG_PAGESIZE_ARG="--pagesize $PAGE_SIZE"
    MKBOOTIMG_SECOND_OFFSET_ARG="--second_offset $SECONDIMAGE_OFFSET"
    ## Boot config
    MKBOOTIMG_CMDLINE_ARG="--cmdline \"$KERNEL_BOOTIMAGE_CMDLINE\""
    MKBOOTIMG_HEADER_VER_ARG="--header_version $KERNEL_BOOTIMAGE_VERSION"
    ## MKBOOTIMG_OUT_IMG_ARG= denined by fn_mkbootmg 
}

fn_initram_get_skel() {
    [ -n "${BOOTIMG_FILES_DIR}" ] || BOOTIMG_FILES_DIR=$(mktemp -d)
    EXTRACTED_INITRAM_DIR="${BOOTIMG_FILES_DIR}/extracted-initram"
    sudo mkdir ${EXTRACTED_INITRAM_DIR}
    sudo chown $(whoami):  ${EXTRACTED_INITRAM_DIR}
    cd ${EXTRACTED_INITRAM_DIR}
    echo "Downloading ${INITRAM_SKEL_IMG}..."
    wget -q ${INITRAM_SKEL_URL}/${INITRAM_SKEL_IMG}
    echo "Extracting the initram skel..."
    gunzip -c ${INITRAM_SKEL_IMG} | cpio -i
    rm -f ${INITRAM_SKEL_IMG}
    echo "Downloading initram boot scripts..."
    cd "${BOOTIMG_FILES_DIR}"
    git clone -b ${INITRAM_BOOTSCRIPTS_BRANCH} ${INITRAM_BOOTSCRIPTS_URL}
    rm -rf initramfs-droidian-boot-scripts/.git
    cp -av initramfs-droidian-boot-scripts/* ${EXTRACTED_INITRAM_DIR}
    cd "${START_DIR}"
}

fn_cpio_version_check() {
    ## cpio 2.13: non bootable on (some?) Android devices
    ## Use 2.12 or 2.15 ir recomendeed
    cpio_found="$(which cpio)"
    [ -n "${cpio_found}" ] && cpio_version="$(cpio --version | head -n 1 | awk '{print $4}')"
    [ "${cpio_version}" == "2.13" ] && cpio_wrong_ver="True" && message "cpio-2.13 detected, but not recomended!"
    if [ "${cpio_wrong_ver}" == "True" ]; then
        echo; echo "Searching for a valid cpio precompiled binary..."
        host_arch="$(uname -m)"
        cpio_bin_found=""
        for file in $(find ./${TOOLS_DIR} -maxdepth 1 -name "cpio-*"); do
            file="$(basename ${file})"
            bin_arch="$(file ./${TOOLS_DIR}/${file} | awk -F',' '{print $2}' | awk '{print $2}')"
            [ "${bin_arch}" == "${host_arch}" ] && cpio_bin="${file}" && cpio_bin_found="True" && break
        done
        [ "${cpio_bin_found}" == "True" ] && message "cpio ${file} selected!" || abort "No vaiid cpio bin found!"
    fi
}

fn_initram_repack() {
    in_initram_dir="${EXTRACTED_INITRAM_DIR}"
    out_initram_dir="${BOOTIMG_FILES_DIR}"
    out_initram_file="ramdisk"
    ## Check that initram extracted dir exists
    [ -e "${in_initram_dir}" ] || abort "The extracted initram dir not exist!"
    [ -e "${out_initram_dir}" ] || abort "The out dir not exist!"
    mv ${out_initram_dir}/ramdisk ${out_initram_dir}/ramdisk_orig
    cd ${in_initram_dir}
    echo && echo "Creating initramfs imatge with cpio..."
    # cpio [--dereference?]
    ## Build initram image
    find ./ -not -path "./.git/*" | sudo cpio -o -R 0:0 --format='newc' | gzip -9 > ${out_initram_dir}/${out_initram_file}
    echo && echo "${out_initram_dir}/${out_initram_file} created"
}

#fn_images_to_include_search() {
    ## Check for files to include
#}

fn_initram_uncompress() {
## TODO
     initram="$(echo ${initram} | awk -F'.' '{print $1}')"
    file_is_compressed=$(file ${initram} | grep -c "gzip")
    if [ "${file_is_compressed}" -eq "1" ]; then
        initram="${initram}.gz"
        gunzip "${initram}"
    fi
    cd ${INPUT_MKBOOT_DIR}
}

fn_mkbootimg() {
    INPUT_MKBOOT_DIR="${BOOTIMG_FILES_DIR}"
    OUTPUT_MKBOOT_DIR="${BOOTIMG_FILES_DIR}"
    INPUT_BOOT_IMAGE="boot.img"
    OUTPUT_BOOT_IMAGE="boot.img_new"
    MKBOOTIMG_OUT_IMG_ARG="-o ${OUTPUT_MKBOOT_DIR}/${OUTPUT_BOOT_IMAGE}"
    ## Check the boot files dir
    [ -d "${INPUT_MKBOOT_DIR}" ] || \
        abort "Dir ${INPUT_MKBOOT_DIR} not found!"
    ## Image creation
    [ -e "${INPUT_MKBOOT_DIR}/kernel" ] || abort "The image file \"kernel\" does not eist!" #&& echo "benne"
    [ -e "${INPUT_MKBOOT_DIR}/ramdisk" ] || abort "The image file \"ramdisk\" does not eist!" #&& echo "benne"
    [ -e "${INPUT_MKBOOT_DIR}/dtb" ] || abort "The image file \"dtb\" does not eist!" #&& echo "benne"
    echo; echo "Creating \" ${OUTPUT_MKBOOT_DIR}/${OUTPUT_BOOT_IMAGE} \" boot image..."
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
	${MKBOOTIMG_OUT_IMG_ARG}
}

fn_flash_bootimage() {
    echo && read -p "Flash the bootimage to the partition \"${BOOT_PART}\"? [ yes | any ]: " answer
    if [ "${answer}" == "yes" ]; then
        sudo dd if=${BOOTIMG_FILES_DIR}/${OUTPUT_BOOT_IMAGE} of="${BOOT_PART}"
    fi
}

## Script execution
if [ "${action}" == "initram-upgrade-bootpart" ]; then
    fn_bootimage_get_from_part
    fn_mkboot_image_config
    fn_cpio_version_check
    fn_initram_get_skel
    fn_initram_repack
    fn_mkbootimg
    fn_flash_bootimage
elif [ "${action}" == "build-initram" ]; then
    fn_cpio_version_check
    fn_initram_repack
elif [ "${action}" == "build-boot" ]; then
    fn_mkbootimg
elif [ "${action}" == "build-all" ]; then
    fn_initram_repack
    fn_mkbootimg
elif [ "${action}" == "initram-get-skel" ]; then
    fn_initram_get_skel
else
    echo; echo "An action should be specified s 2nd script argument!"
    echo; echo "Valid actions:"
    echo "  \" build-all \": Do a initram repack and builds the boot image."
    echo "  \" build-boot \": Builds the boot image with the files in exttracted-boot dir."
    echo "  \" build-initram \": Repacks the initram using the content on extracted-boot/extracted-ramdisk"
    echo "  \" initram-get-skel \": Downloads a initramfs image as template and updates the boot scripts"
    echo "  \" initram-upgrade-bootpart \": Extracts the boot.img from boot partition, dounload a initram skel, update initram bootscripts, rebuuild the boot.img, and flash them."
fi
