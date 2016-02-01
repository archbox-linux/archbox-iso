#!/usr/bin/bash

DEVICES=`lsblk -lno NAME,FSTYPE,SIZE,LABEL | egrep "(ext(2|3|4)|reiserfs|btrfs|reiser4)"`

cnt=0
#for dev in `lsblk -lo NAME,FSTYPE,SIZE,LABEL | egrep "(ext(2|3|4)|reiserfs|btrfs|reiser4)" | grep -o ^[^[:space:]]*`; do
while read -r dev; do
    (( cnt++ ))
    dlgParams+=( "$cnt" "$dev" "off" )
    #echo "${cnt} \"${dev}\" off";
done <<< "$DEVICES"

#echo "${dlgParams[@]}"

if [ $cnt -ne 0 ]; then
    dialog --backtitle "Choose device for new root" --radiolist "Available devices:" 15 40 10  "${dlgParams[@]}"
fi
