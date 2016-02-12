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

mount_new_root "/dev/$ROOT_DEV" "/mnt/"
echo $?
exit

RES=$?
if [ "$RES" -ne 0 ]; then
  echo "Failed to mount new root"
  exit 3
fi

