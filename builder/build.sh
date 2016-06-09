#!/bin/bash -e
set -x
# This script should be run only inside of a Docker container
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script works only in a Docker container!"
  exit 1
fi

# get versions for software that needs to be installed
source /workspace/versions.config

### setting up some important variables to control the build process

# place to store our created sd-image file
BUILD_RESULT_PATH="/workspace"

# place to build our sd-image
BUILD_PATH="/build"

ROOTFS_TAR="rootfs-armhf-raspbian-${HYPRIOT_OS_VERSION}.tar.gz"
ROOTFS_TAR_PATH="${BUILD_RESULT_PATH}/${ROOTFS_TAR}"

# Show TRAVSI_TAG in travis builds
echo TRAVIS_TAG="${TRAVIS_TAG}"

# name of the sd-image we gonna create
HYPRIOT_IMAGE_VERSION=${VERSION:="dirty"}
HYPRIOT_IMAGE_NAME="hypriotos-rpi-${HYPRIOT_IMAGE_VERSION}.img"
export HYPRIOT_IMAGE_VERSION

# download the ready-made raw image for the RPi
if [ ! -f "${BUILD_RESULT_PATH}/${RAW_IMAGE}.zip" ]; then
  wget -q -O "${BUILD_RESULT_PATH}/${RAW_IMAGE}.zip" "https://github.com/hypriot/image-builder-raw/releases/download/${RAW_IMAGE_VERSION}/${RAW_IMAGE}.zip"
fi

# verify checksum of the ready-made raw image
echo "${RAW_IMAGE_CHECKSUM} ${BUILD_RESULT_PATH}/${RAW_IMAGE}.zip" | sha256sum -c -

unzip -p "${BUILD_RESULT_PATH}/${RAW_IMAGE}" > "/${HYPRIOT_IMAGE_NAME}"

# create build directory for assembling our image filesystem
rm -rf ${BUILD_PATH}
mkdir -p ${BUILD_PATH}/boot

# download our base root file system
if [ ! -f "${ROOTFS_TAR_PATH}" ]; then
  wget -q -O "${ROOTFS_TAR_PATH}" "https://github.com/hypriot/os-rootfs/releases/download/${HYPRIOT_OS_VERSION}/${ROOTFS_TAR}"
fi

# verify checksum of our root filesystem
echo "${ROOTFS_TAR_CHECKSUM} ${ROOTFS_TAR_PATH}" | sha256sum -c -

# configure and build BananaPi
git clone --depth 1 https://github.com/LeMaker/lemaker-bsp.git ./lemaker/
cd lemaker/
tree -L 2 .
./configure BananaPi
make
tree -L 2 .
ls -lAh output/BananaPi_hwpack/ || true
cd ..

# extract root file system
tar xzf "${ROOTFS_TAR_PATH}" -C "${BUILD_PATH}"

# copy new compiled files to filesystem
cp -r ${BUILD_RESULT_PATH}/lemaker/build/BananaPi_hwpack/kernel/* ${BUILD_PATH}/boot
cp -r ${BUILD_RESULT_PATH}/lemaker/build/BananaPi_hwpack/rootfs/* ${BUILD_PATH}

# modify/add image files directly
# e.g. root partition resize script
cp -R /builder/files/* ${BUILD_PATH}/

echo "
bootargs=console=ttyS0,115200 disp.screen0_output_mode=EDID:1024x768p50 hdmi.audio=EDID:0 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
aload_script=fatload mmc 0 0x43000000 script.bin;
aload_kernel=fatload mmc 0 0x48000000 uImage;bootm 0x48000000;
uenvcmd=run aload_script aload_kernel
" > ${BUILD_PATH}/boot/uEnv.txt


# register qemu-arm with binfmt
# to ensure that binaries we use in the chroot
# are executed via qemu-arm
update-binfmts --enable qemu-arm

# set up mount points for the pseudo filesystems
mkdir -p ${BUILD_PATH}/{proc,sys,dev/pts}

mount -o bind /dev ${BUILD_PATH}/dev
mount -o bind /dev/pts ${BUILD_PATH}/dev/pts
mount -t proc none ${BUILD_PATH}/proc
mount -t sysfs none ${BUILD_PATH}/sys

# make our build directory the current root
# and install the Rasberry Pi firmware, kernel packages,
# docker tools and some customizations
chroot ${BUILD_PATH} /bin/bash < /builder/chroot-script.sh

# unmount pseudo filesystems
umount -l ${BUILD_PATH}/dev/pts
umount -l ${BUILD_PATH}/dev
umount -l ${BUILD_PATH}/proc
umount -l ${BUILD_PATH}/sys

# package image filesytem into two tarballs - one for bootfs and one for rootfs
# ensure that there are no leftover artifacts in the pseudo filesystems
rm -rf ${BUILD_PATH}/{dev,sys,proc}/*

tar cf filesystem.tar -C ${BUILD_PATH} .

ROOT_PARTITION_OFFSET=$(fdisk -l /${HYPRIOT_IMAGE_NAME} | grep ${HYPRIOT_IMAGE_NAME}2 | awk -F " " '{ print $2 }')
BOOT_PARTITION_OFFSET=$(fdisk -l /${HYPRIOT_IMAGE_NAME} | grep ${HYPRIOT_IMAGE_NAME}1 | awk -F " " '{ print $2 }')

mount -t ext4 -o loop=/dev/loop0,offset=$((ROOT_PARTITION_OFFSET*512)) "/${HYPRIOT_IMAGE_NAME}" ${BUILD_PATH}
mkdir ${BUILD_PATH}/boot
mount -t msdos -o loop=/dev/loop1,offset=$((BOOT_PARTITION_OFFSET*512)) "/${HYPRIOT_IMAGE_NAME}" ${BUILD_PATH}/boot

tar xf filesystem.tar -C ${BUILD_PATH}

umount ${BUILD_PATH}/boot
umount ${BUILD_PATH}

dd if="${BUILD_RESULT_PATH}/lemaker/build/BananaPi_hwpack/bootloader/u-boot-sunxi-with-spl.bin" of="/${HYPRIOT_IMAGE_NAME}" bs=1MiB seek=8


# ensure that the travis-ci user can access the sd-card image file
umask 0000

# compress image
zip "${BUILD_RESULT_PATH}/${HYPRIOT_IMAGE_NAME}.zip" "/${HYPRIOT_IMAGE_NAME}"
cd ${BUILD_RESULT_PATH} && sha256sum "${HYPRIOT_IMAGE_NAME}.zip" > "${HYPRIOT_IMAGE_NAME}.zip.sha256" && cd -

exit 0
# test sd-image that we have built
VERSION=${HYPRIOT_IMAGE_VERSION} rspec --format documentation --color ${BUILD_RESULT_PATH}/builder/test
