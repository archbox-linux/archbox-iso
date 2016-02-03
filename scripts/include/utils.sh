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

