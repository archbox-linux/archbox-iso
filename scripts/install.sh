#!/usr/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$SCRIPT_DIR/include/utils.sh"

ROOT_DEV=$(show_select_devices)
RES=$?

if [ "$RES" -ne 0 ]; then
	echo "Canceled by user. Exiting."
	exit 1
fi

if [ "s$ROOT_DEV" = "s" ]; then
	echo "No target defined. Exiting."
	exit 2
fi

mount_new_root "/dev/$ROOT_DEV" "/mnt"
RES=$?
if [ "$RES" -ne 0 ]; then
  echo "Failed to mount new root"
  exit 3
fi

copy_to_new_root "/mnt"
RES=$?
if [ "$RES" -ne 0 ]; then
  echo "Failed to copy to new root"
  exit 4
fi

# copy the kernel image to the new root, in order to keep the integrity of the new system
cp -vaT /run/archiso/bootmnt/arch/boot/$(uname -m)/vmlinuz /mnt/boot/vmlinuz-linux

# generate a fstab
genfstab -U "/mnt" > /mnt/etc/fstab

remove_live_trails "/mnt"

# Create an initial ramdisk environment
arch-chroot "/mnt" mkinitcpio -p linux

install_grub "/mnt" "$ROOT_DEV"
