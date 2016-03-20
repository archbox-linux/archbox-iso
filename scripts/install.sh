#!/usr/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$SCRIPT_DIR/include/utils.sh"

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

TMPDIR="/tmp/"
CONFIGNAME="archbox"
BACKTITLE="Archbox Install"

#rm ${TMPDIR}${CONFIGNAME}.*

STEP=1

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "Archbox Install" \
    --title "Installation steps" \
    --clear \
    --cancel-label "Exit" \
    --default-item "$STEP" \
    --menu "" $HEIGHT $WIDTH 8 \
    "1" "Select drive" \
    "2" "Personal information" \
    "3" "Locale" \
    "4" "Timezone" \
    "5" "Bootloader" \
    "6" "Install" \
    "7" "Reboot" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Installation terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Installation aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    0 )
      clear
      echo "Installation terminated."
      ;;
    1 )
      #if [ $STEP -eq 0 ]; then continue; fi
      select_device "${STEP}"
      ROOT_DEV=$( get_saved_params "1" )
      if [ "s$ROOT_DEV" = "s" ]; then
        #echo "No target defined. Exiting."
        continue
      fi
      STEP=2
      ;;
    2 )
      #if [ $STEP -eq 0 ]; then continue; fi
      if [ $STEP -lt 2 ]; then continue; fi
      select_user_params "2"
      RES=$?
      if [ $RES -eq 0 ]; then
        if check_user_params ; then
          STEP=3
        fi
      fi
      ;;
    3 )
      #if [ $STEP -eq 0 ]; then continue; fi
      if [ $STEP -lt 3 ]; then continue; fi
      select_language "3"
      RES=$?
      if [ $RES -eq 0 ]; then
        STEP=4
      fi
      ;;
    4 )
      #if [ $STEP -eq 0 ]; then continue; fi
      if [ $STEP -lt 4 ]; then continue; fi
      select_timezone "4"
      RES=$?
      if [ $RES -eq 0 ]; then
        TZ=$( get_saved_params "4" )
        if [ "s$TZ" != "s" ]; then
          STEP=5
        fi
      fi
      ;;
    5 )
      #if [ $STEP -eq 0 ]; then continue; fi
      if [ $STEP -lt 5 ]; then continue; fi
      select_bootloader "5"
      #RES=$?
      #if [ $RES -eq 0 ]; then
        STEP=6
      #fi
      ;;
    6 )
      #if [ $STEP -eq 0 ]; then continue; fi
      if [ $STEP -lt 6 ]; then continue; fi
      confirm_install
      RES=$?
      if [ $RES -eq 0 ]; then
        do_install
        STEP=7
      fi
      ;;
    7 )
      if [ $STEP -lt 7 ]; then continue; fi
      do_reboot
      ;;
  esac
done
