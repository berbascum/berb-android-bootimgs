#!/bin/bash

## Berbascum 2024  v1.0.0-1
 # Create boot.img_post_build with files in kernel output dir

# Requeriments
  # apt-get install mkbootimg  ## Tested with the Debiann Bookworm's apt version
  # Some vars need to be defined with specific information
    # KERNEL_SOURCES_PATH need to be defined with own kernel sources root_dir
    # VAR KERNEL_BOOTIMAGE_CMDLINE need to be defined with device specific values
    # VARS in "Image configuration values" need to be defined with device specific values


## SAMPLE CALLS ##
## Build boot.img
## ./berb-bootimg-mkbootimg-creator.sh vayu droidian-booitmg-develop/extracted-boot-vayu/ droidian
## initram repack
## ./berb-bootimg-mkbootimg-creator.sh vayu droidian-booitmg-develop/extracted-boot-vayu/ droidian initram-repack


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

## Global vars
fn_mkboot_conf_global() {
    ## Arguments definition for mkbootimg
    ## Paths
    ## kernel
    MKBOOTIMG_KERNEL_ARG="--kernel ${INPUT_MKBOOT_DIR}/${kernel}"
    MKBOOTIMG_KERNEL_OFFSET_ARG="--kernel_offset $KERNEL_OFFSET"
    MKBOOTIMG_TAGS_OFFSET_ARG="--tags_offset $TAGS_OFFSET"
    MKBOOTIMG_OS_PATCH_LVL_ARG="--os_patch_level ${OS_PATCH_LVL}"
    ## dtb
    MKBOOTIMG_DTB_ARG="--dtb ${INPUT_MKBOOT_DIR}/${dtb}"
    MKBOOTIMG_DTB_OFFSET_ARG="--dtb_offset $DTB_OFFSET"
    ## ramdisk
    MKBOOTIMG_RAMDISK_ARG="--ramdisk ${INPUT_MKBOOT_DIR}/${initram}"
    MKBOOTIMG_RAMDISK_OFFSET_ARG="--ramdisk_offset $INITRAMFS_OFFSET"
    ## other offssets
    MKBOOTIMG_BASE_ARG="--base $BASE_OFFSET"
    MKBOOTIMG_PAGESIZE_ARG="--pagesize $PAGE_SIZE"
    MKBOOTIMG_SECOND_OFFSET_ARG="--second_offset $SECONDIMAGE_OFFSET"
    ## Boot config
    MKBOOTIMG_CMDLINE_ARG="--cmdline \"$KERNEL_BOOTIMAGE_CMDLINE\""
    MKBOOTIMG_HEADER_VER_ARG="--header_version $KERNEL_BOOTIMAGE_VERSION"
    MKBOOTIMG_OUT_IMG_ARG="-o ${INPUT_MKBOOT_DIR}/${MKBOOTIMG_OUT_IMG}"
}

fn_initram_unpack() {
## TODO
     initram="$(echo ${initram} | awk -F'.' '{print $1}')"
    file_is_compressed=$(file ${initram} | grep -c "gzip")
    if [ "${file_is_compressed}" -eq "1" ]; then
        initram="${initram}.gz"
        gunzip "${initram}"
    fi
    cd ${INPUT_MKBOOT_DIR}
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
    ## Check that initram extracted dir exists
    [ -e "${EXTRACTED_INITRAM_DIR}" ] || abort "The extracted initram dir not exist!"
    out_initram_dir="${INPUT_MKBOOT_DIR}"
    out_initram_file="${initram}"
    cd ${EXTRACTED_INITRAM_DIR}
    echo && echo "Creating initramfs imatge with cpio..."
    # cpio [--dereference?]
    ## Build initram image
    sudo rm -f ${START_DIR}/${INPUT_MKBOOT_DIR}/${out_initram_file}
    find ./ -not -path "./.git/*" | sudo cpio -o -R 0:0 --format='newc' | gzip -9 > ${START_DIR}/${out_initram_dir}/${out_initram_file}
    echo && echo "${START_DIR}/${out_initram_dir}/${out_initram_file} created"
}

#fn_images_to_include_search() {
    ## Check for files to include
#}

fn_mkbootimg() {
## Check the boot files dir
    [ -d "${INPUT_MKBOOT_DIR}" ] || \
        abort "Dir ${INPUT_MKBOOT_DIR} not found!"
    ## Image creation
    sudo rm ${INPUT_MKBOOT_DIR}/${MKBOOTIMG_OUT_IMG}
    echo; echo "Creating \" ${INPUT_MKBOOT_DIR}/${MKBOOTIMG_OUT_IMG} \" boot image..."
    [ -e "${INPUT_MKBOOT_DIR}/${kernel}" ] || abort "The image file \"${kernel}\" does not eist!" #&& echo "benne"
    [ -e "${INPUT_MKBOOT_DIR}/${initram}" ] || abort "The image file \"${initram}\" does not eist!" #&& echo "benne"
    [ -e "${INPUT_MKBOOT_DIR}/${dtb}" ] || abort "The image file \"${dtb}\" does not eist!" #&& echo "benne"
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


## Script execution
fn_mkboot_conf_global
if [ "${action}" == "build-initram" ]; then
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
fi
