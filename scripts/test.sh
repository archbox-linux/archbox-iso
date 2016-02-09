#!/usr/bin/bash


CNT=0

NUM=$( find / -mount | wc -l )

PERCENTAGE=0
PREV_PERCENTAGE=-1

dialog --title "Installing system to new root" --gauge "Please wait" 8 70 < <(
  while read -r str; do 
	(( CNT++ ))
	let UPD=CNT%100
	let PERCENTAGE=100*CNT/NUM
	# get 30 chars at the end of fname
	if [ ${#str} -gt 30 ]; then 
		fname="...${str:${#str}-30:30}"
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
