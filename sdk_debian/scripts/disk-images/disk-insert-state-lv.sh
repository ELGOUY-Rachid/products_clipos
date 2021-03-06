#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2017-2018 ANSSI. All rights reserved.

# This script:
#   * creates a Logical Volume with name LV_NAME and size LV_SIZE inside the
#     image IMAGE_DISK_FILE
#   * creates an empty ext4 filesystem inside the Logical Volume
#   * extract the tar archive TAR_FILE inside the ext4 filesystem

# Safety settings: do not remove!
set -o errexit -o nounset -o pipefail

# The prelude to every script for this SDK. Do not remove it.
source /mnt/products/${CURRENT_SDK_PRODUCT}/${CURRENT_SDK_RECIPE}/scripts/prelude.sh

readonly IMAGE_DISK_FILE="${1:?IMAGE_DISK_FILE is needed}"
readonly TAR_FILE="${2:?TAR_FILE is needed}"
readonly LV_NAME="${3:?LV_NAME is needed}"
readonly LV_SIZE="${4:?LV_SIZE is needed}"

# Main LVM volume group name
readonly VG_NAME="${CURRENT_PRODUCT_PROPERTY['system.disk_layout.vg_name']}"

if [[ ! -f "${IMAGE_DISK_FILE}" ]]; then
    die "${IMAGE_DISK_FILE} does not exist!"
fi
if [[ ! -f "${TAR_FILE}" ]]; then
    die "${TAR_FILE} does not exist!"
fi

# We make use of libguestfs in the following commands to create the disk image
# where CLIP will be installed. This environment variable tells libguestfs to
# use directly QEMU-KVM without the need of the libvirt daemon.
export LIBGUESTFS_BACKEND=direct

ebegin "Adding ${TAR_FILE} in ${LV_NAME}:${LV_SIZE}M in ${IMAGE_DISK_FILE}..."

guestfish --rw <<_EOF_
add-drive ${IMAGE_DISK_FILE} label:main

run

lvcreate ${LV_NAME} ${VG_NAME} ${LV_SIZE}
mkfs ext4 /dev/${VG_NAME}/${LV_NAME}
mount /dev/${VG_NAME}/${LV_NAME} /
tar-in ${TAR_FILE} /
_EOF_
eend "Done"

# vim: set ts=4 sts=4 sw=4 et ft=sh:
