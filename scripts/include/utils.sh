#!/usr/bin/bash

show_select_devices() {
  IFS=$'\n'
  DEVICES_LIST=$( lsblk -lno NAME,SIZE,FSTYPE,LABEL | egrep "(ext(2|3|4)|reiserfs|btrfs|reiser4)" )
  unset IFS

  CNT=0

  while read -r dev; do
    (( CNT++ ))
    devName=$( echo ${dev} | awk '{ print $1 }' )
    devDescr=$( echo ${dev} | awk '{ print $2 " " $3 " " $4 }' )
    dlgParams+=( "${devName}" "${devDescr}" "off" )
  done <<< "$DEVICES_LIST"

  if [ $( echo "$dlgParams" | wc -l ) -gt 0 ]; then
    ROOT_DEV=$( dialog --backtitle "Choose device for new root" --radiolist "Available devices:" $( expr ${CNT} + 7 ) 50 ${CNT}  "${dlgParams[@]}" 2>&1 1>/dev/tty )
    RES=$?
  fi

  echo $ROOT_DEV

  return $RES
}

mount_new_root() {
  NEWROOT_DEV=$1
  NEWROOT_MOUNT_DIR=$2

  # check if newroot already mounted
  if [ $( findmnt --source "${NEWROOT_DEV}" ) ]; then
  # check if newroot_mount_dir already busy
    if [ $( findmnt --mountpoint ${NEWROOT_MOUNT_DIR} ) ]; then
      mount "${NEWROOT_DEV}" "${NEWROOT_MOUNT_DIR}"
      exit $?
    fi
  fi
}

copy_to_new_root() {

  CNT=0

  FNAME_TITLE_SIZE=30

  NUM=$( find / -mount | wc -l )

  PERCENTAGE=0
  PREV_PERCENTAGE=-1

  dialog --title "Installing system to new root" --gauge "Please wait" 8 70 < <(
    while read -r str; do
    (( CNT++ ))
    let UPD=CNT%100
    let PERCENTAGE=100*CNT/NUM
    # get FNAME_TITLE_SIZE chars at the end of fname
    if [ ${#str} -gt ${FNAME_TITLE_SIZE} ]; then
      fname="...${str:${#str}-${FNAME_TITLE_SIZE}:${FNAME_TITLE_SIZE}"
    else
      fname=${str}
    fi
    if [ $UPD -eq 0 ]; then
cat <<EOF
XXX
$PERCENTAGE

Copying file "$fname"
XXX
EOF
    fi
  done < <( rsync -ax --info=name1 / /mnt )
)

}
