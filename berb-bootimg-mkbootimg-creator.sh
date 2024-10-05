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

tools_dir="tools"
target_os="droidian"
input_mkboot_dir="droidian-booitmg-develop/mkboot-files"
kernel="kernel"
initrd="ramdisk.cpio"
dtb="dtb"



abort() {
    echo
    echo "$*"
    exit 1
}
message() {
    echo
    echo "$*"
}


## device_target required
device_target="$1"
[ -z "${device_target}" ] && abort "A device target name is required as 1st script arg"

## Device mkbootimg config file required
[ -e "./mkbootimg-config-${device_target}.sh" ] \
    && source ./mkbootimg-config-${device_target}.sh \
    || abort "Device config file missing"


## Set action var
action="$2"

## Global vars
fn_vars_set_img_conf() {
    ## Arguments definition for mkbootimg
    ## Paths
    MKBOOTIMG_OUT_IMG="boot-berb-${target_os}-${device_target}.img"
    ## kernel
    MKBOOTIMG_KERNEL_ARG="--kernel ${input_mkboot_dir}/${kernel}"
    MKBOOTIMG_KERNEL_OFFSET_ARG="--kernel_offset $KERNEL_OFFSET"
    MKBOOTIMG_TAGS_OFFSET_ARG="--tags_offset $TAGS_OFFSET"
    MKBOOTIMG_OS_PATCH_LVL_ARG="--os_patch_level ${OS_PATCH_LVL}"
    ## dtb
    MKBOOTIMG_DTB_ARG="--dtb ${input_mkboot_dir}/${dtb}"
    MKBOOTIMG_DTB_OFFSET_ARG="--dtb_offset $DTB_OFFSET"
    ## ramdisk
    MKBOOTIMG_RAMDISK_ARG="--ramdisk ${input_mkboot_dir}/${initrd}"
    MKBOOTIMG_RAMDISK_OFFSET_ARG="--ramdisk_offset $INITRAMFS_OFFSET"
    ## other offssets
    MKBOOTIMG_BASE_ARG="--base $BASE_OFFSET"
    MKBOOTIMG_PAGESIZE_ARG="--pagesize $PAGE_SIZE"
    MKBOOTIMG_SECOND_OFFSET_ARG="--second_offset $SECONDIMAGE_OFFSET"
    ## Boot config
    MKBOOTIMG_CMDLINE_ARG="--cmdline \"$KERNEL_BOOTIMAGE_CMDLINE\""
    MKBOOTIMG_HEADER_VER_ARG="--header_version $KERNEL_BOOTIMAGE_VERSION"
    MKBOOTIMG_OUT_IMG_ARG="-o ${input_mkboot_dir}/${MKBOOTIMG_OUT_IMG}"
}



fn_initram_unpack() {
## TODO
     initrd="$(echo ${initrd} | awk -F'.' '{print $1}')"
    file_is_compressed=$(file ${initrd} | grep -c "gzip")
    if [ "${file_is_compressed}" -eq "1" ]; then
        initrd="${initrd}.gz"
        gunzip "${initrd}"
    fi
    cd ${input_mkboot_dir}
}

fn_initram_repack() {
## With cpio 2.13, the resulting initram file i not able to boot on (some?) Android devices. 2.15 should be used.
    cpio_found="$(which cpio)"
    [ -n "${cpio_found}" ] && cpio_version="$(cpio --version | head -n 1 | awk '{print $4}')"
    [ "${cpio_version}" == "2.13" ] && cpio_wrong_ver="True" && message "cpio-2.13 detected, but not recomended!"
    if [ "${cpio_wrong_ver}" == "True" ]; then
        echo; echo "Searching for a valid cpio precompiled binary..."
        host_arch="$(uname -m)"
        cpio_bin_found=""
        for file in $(find ./${tools_dir} -maxdepth 1 -name "cpio-*"); do
            file="$(basename ${file})"
            bin_arch="$(file ./${tools_dir}/${file} | awk -F',' '{print $2}' | awk '{print $2}')"
            [ "${bin_arch}" == "${host_arch}" ] && cpio_bin="${file}" && cpio_bin_found="True" && break
        done
        [ "${cpio_bin_found}" == "True" ] && message "cpio ${file} selected!" || abort "No vaiid cpio bin found!"
    fi

    ## Paths definition
    START_DIR=$(pwd)
    in_dir="droidian-booitmg-develop/extracted-initram"
    out_dir="droidian-booitmg-develop/initrd-images"
    out_file="ramdisk.cpio-berb.gz"
    ## Check that initram extracted dir exists
    [ -e "${in_dir}/scripts/functions" ] || abort "The extracted initram dir not exist!"
    cd ${in_dir}
    echo && echo "Creating initramfs imatge with cpio..."
    # cpio [--dereference?]
    ## Build initram image

    sudo rm ${START_DIR}/${input_mkboot_dir}/${initrd}
    sudo find . | sudo cpio -o -R 0:0 --format='newc' | gzip -9 > ${START_DIR}/${input_mkboot_dir}/${initrd}
    #sudo cp -av "${out_file}" "${initrd}"
    echo && echo "${START_DIR}/${input_mkboot_dir}/${initrd} created"
}

#fn_images_to_include_search() {
    ## Check for files to include
#}

fn_mkbootimg() {
## Check the boot files dir
[ ! -d "${input_mkboot_dir}" ] && abort "Dir with the files to include in the boot image not found"
    ## Image creation
    sudo rm ${input_mkboot_dir}/${MKBOOTIMG_OUT_IMG}
    echo; echo "Creating \" ${input_mkboot_dir}/${MKBOOTIMG_OUT_IMG} \" boot image..."
    [ -e "${input_mkboot_dir}/${kernel}" ] || abort "The image file \"${kernel}\" does not eist!" #&& echo "benne"
    [ -e "${input_mkboot_dir}/${initrd}" ] || abort "The image file \"${initrd}\" does not eist!" #&& echo "benne"
    [ -e "${input_mkboot_dir}/${dtb}" ] || abort "The image file \"${dtb}\" does not eist!" #&& echo "benne"
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
fn_vars_set_img_conf
if [ "${action}" == "build-initram" ]; then
    fn_initram_repack
elif [ "${action}" == "build-boot" ]; then
    fn_mkbootimg
elif [ "${action}" == "build-all" ]; then
    fn_initram_repack
    fn_mkbootimg
else
    echo; echo "An action should be specified s 2th script argument!"
    echo; echo "Valid actions:"
    echo "  \" build-all     \": Do a initram repack and builds the boot image."
    echo "  \" build-boot    \": Builds the boot image with the files in exttracted-boot dir."
    echo "  \" build-initram \": Repacks the initram using the content on extracted-boot/extracted-ramdisk"
fi
