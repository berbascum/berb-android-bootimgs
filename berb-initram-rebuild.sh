#!/bin/bash

START_DIR=$(pwd)
LOOP_DEV="/dev/block/loop31"
MOUNT_POINT="/media/boot"
INITRAMFS_DIR="initramfs"
INITRAMFS_EXTRACTED_DIR="${INITRAMFS_DIR}/extracted-berb-mobian"
INITRANFS_FILE="initrd.img-6.1-sdm845"
INITRANFS_FILE_BERB="initrd.img-6.1-sdm845-berb"
BOOT_IMGS_DIR="boot-imgs/debian-boot"
IMAGE_BERB="mobian-sdm845-phosh-12.0.boot_berb_raw.img"

cd ${INITRAMFS_EXTRACTED_DIR}
echo && echo "Creant imatge initramfs amb cpio..."
find . | cpio --dereference -o -H newc  > ${START_DIR}/${INITRAMFS_DIR}/${INITRANFS_FILE}
zstd -9 ${START_DIR}/${INITRAMFS_DIR}/${INITRANFS_FILE_BERB}

cd ${START_DIR}
echo && echo "Muntant imatge boot per a substituir l'initramfs"
losetup ${LOOP_DEV} ${BOOT_IMGS_DIR}/${IMAGE_BERB}
mkdir ${MOUNT_POINT} >/dev/null
mount ${LOOP_DEV} ${MOUNT_POINT}
echo && echo "Actualitzant l'initramfs de la imatge boot"
cat  ${INITRAMFS_DIR}/${INITRANFS_FILE_BERB}.zst > ${MOUNT_POINT}/${INITRANFS_FILE}
echo && echo "Desmuntant imatge boot un cop actualitzada:"
sync
umount ${MOUNT_POINT}
losetup -d ${LOOP_DEV}

echo && echo "Imatge actualitzada: ${START_DIR}/${BOOT_IMGS_DIR}/${IMAGE_BERB}"
