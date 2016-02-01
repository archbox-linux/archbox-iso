#!/usr/bin/bash


cnt=0
for dev in `lsblk -fnl | egrep "(ext(2|3|4)|reiserfs|btrfs|reiser4)" | grep -o ^[^[:space:]]*`; do
    (( cnt++ ))
    dlgParams+=" ${cnt} ${dev} off"
done

if [ $cnt -ne 0 ]; then
    dialog --backtitle "Choose device for new root" --radiolist "Available devices:" 15 40 10  $dlgParams
fi