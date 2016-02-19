#!/usr/bin/bash

display_info() {
  dialog --title "" \
    --no-collapse \
    --msgbox "$1" 0 0
}

# args: 1 - installation step
get_saved_params() {
  cat "${TMPDIR}${CONFIGNAME}.${1}"
}

select_device() {

  SFX=$1

  IFS=$'\n'
  DEVICES_LIST=$( lsblk -lpno NAME,SIZE,FSTYPE,LABEL | egrep "(ext(2|3|4)|reiserfs|btrfs|reiser4)" )
  unset IFS

  CNT=0
  while read -r dev; do
    (( CNT++ ))
    devName=$( echo ${dev} | awk '{ print $1 }' )
    devDescr=$( echo ${dev} | awk '{ print $2 " " $3 " " $4 }' )
    dlgParams+=( "${devName}" "${devDescr}" "off" )
  done <<< "$DEVICES_LIST"

  if [ $( echo "$dlgParams" | wc -l ) -gt 0 ]; then
    dialog --backtitle "${BACKTITLE}" --radiolist "Choose device for new root:" $( expr ${CNT} + 7 ) 50 ${CNT} \
    "${dlgParams[@]}" \
    2>"${TMPDIR}${CONFIGNAME}.${SFX}"
    RES=$?
  fi

  return $RES
}

mount_new_root() {
  NEWROOT_DEV=$1
  NEWROOT_MOUNT_DIR=$2

  # try to umount
  umount "${NEWROOT_DEV}"


  # check if newroot already mounted
  if ! findmnt --source "${NEWROOT_DEV}" > /dev/null ; then
  # check if newroot_mount_dir already busy
    if ! findmnt --mountpoint "${NEWROOT_MOUNT_DIR}" > /dev/null ; then
      mount "${NEWROOT_DEV}" "${NEWROOT_MOUNT_DIR}"
      return $?
    else
      echo "${NEWROOT_MOUNT_DIR} is busy"
      return 2
    fi
  else
    echo "${NEWROOT_DEV} is already mounted"
    return 1
  fi
}

copy_to_new_root() {

  NEWROOT_MOUNT_DIR=$1

  CNT=0

  FNAME_TITLE_SIZE=30

  NUM=$( find / -mount | wc -l )

  #echo $NUM

  PERCENTAGE=0
  PREV_PERCENTAGE=-1

  dialog --backtitle "${BACKTITLE}" --title "Installing system to new root" --gauge "Please wait" 8 70 < <(
    while read -r str; do
    (( CNT++ ))
    let UPD=CNT%100
    let PERCENTAGE=100*CNT/NUM
    # get FNAME_TITLE_SIZE chars at the end of fname
    if [ ${#str} -gt $FNAME_TITLE_SIZE ]; then
      fname="...${str:${#str}-${FNAME_TITLE_SIZE}:${FNAME_TITLE_SIZE}}"
    else
      fname=${str}
    fi
    if [ $UPD -eq 0 ]; then
cat <<EOF
XXX
$PERCENTAGE

Copying file $fname
XXX
EOF
    fi
  done < <( rsync -ax --info=name1 / ${NEWROOT_MOUNT_DIR} )
)

}

# get rid of the trace of a Live environment
remove_live_trails() {

  NEWROOT_MOUNT_DIR=$1

  # remove live user
  userdel -rf --root "${NEWROOT_MOUNT_DIR}" "archbox"

  # Restore the configuration of journald:
  sed -i 's/Storage=volatile/#Storage=auto/' "${NEWROOT_MOUNT_DIR}/etc/systemd/journald.conf"

  # Remove special udev rule that starts the dhcpcd automatically:
  rm "${NEWROOT_MOUNT_DIR}/etc/udev/rules.d/81-dhcpcd.rules"

  # Disable and remove the services created by archiso:
  rm "${NEWROOT_MOUNT_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf"
  rm "${NEWROOT_MOUNT_DIR}/root/{.automated_script.sh,.zlogin}"
  rm "${NEWROOT_MOUNT_DIR}/etc/mkinitcpio-archiso.conf"
  rm -r "${NEWROOT_MOUNT_DIR}/etc/initcpio"

  # Remove installer
  rm -r "${NEWROOT_MOUNT_DIR}/opt/archbox"

  # remove installer from obmenu
  sed -i '/\/opt\/archbox\/install.sh/d' "${NEWROOT_MOUNT_DIR}/etc/skel/.config/obmenu-generator/schema.pl"

  # restore issue screen
  echo 'Arch Linux \r (\l)'>"${NEWROOT_MOUNT_DIR}/etc/issue"
  echo >>"${NEWROOT_MOUNT_DIR}/etc/issue"
  echo >>"${NEWROOT_MOUNT_DIR}/etc/issue"
}

install_grub() {
  NEWROOT_MOUNT_DIR=$1
  ROOT_DEV=$2
  BOOT_DISK=$( lsblk -plno PKNAME,NAME | grep "${ROOT_DEV}" | awk '{print $1}' )

  arch-chroot "${NEWROOT_MOUNT_DIR}" grub-install --target=i386-pc --recheck "${BOOT_DISK}"

  arch-chroot "${NEWROOT_MOUNT_DIR}" grub-mkconfig -o /boot/grub/grub.cfg
}

select_user_params() {
  SFX=$1

  i=0
  while read line; do
    userParams[$i]="$line"
    (( i++ ))
  done < <( get_saved_params "2" )
  comp=${userParams[0]:="archbox"}
  user=${userParams[1]:="archuser"}
  psw=${userParams[2]}
  psw2=${userParams[3]}

  dialog \
      --backtitle "${BACKTITLE}" \
      --title "Personal information" \
      --insecure \
      --visit-items \
      --mixedform "" \
  15 50 0 \
    "Computer name:"    1 1 "${comp}"  1 16 15 0 0 \
    "Username:"         2 1 "${user}"  2 16 15 0 0 \
    "Password:"         3 1 "${psw}"   3 16 15 0 1 \
    "Confirm:"          4 1 "${psw2}"  4 16 15 0 1 \
   2>"${TMPDIR}${CONFIGNAME}.${SFX}"

  RES=$?
  if [ $RES -eq 0 ]; then
    check_user_params
    if  [ $? -ne 0 ]; then
      select_user_params "${SFX}"
    fi
  fi

  clear

  return $RES
}

check_user_params() {
  i=0
  while read line; do
    userParams[$i]="$line"
    (( i++ ))
  done < <( get_saved_params "2" )
  comp=${userParams[0]}
  user=${userParams[1]}
  psw=${userParams[2]}
  psw2=${userParams[3]}

  if [ "s${comp}" = "s" ]; then
    display_info "Computer name cannot be empty"
    return 1
  fi
  if [ "s${user}" = "s" ]; then
    display_info "Username cannot be empty"
    return 1
  fi
  if [ "s${psw}" = "s" ]; then
    display_info "Password cannot be empty"
    return 1
  fi
  if [ "s${psw}" != "s${psw2}" ]; then
    display_info "Password and confirmation mismatch"
    return 1
  fi

  return 0
}

select_language() {

  SFX=$1

  IFS=$'\n'
  LOCALES_LIST=( $( cat /etc/locale.gen | awk '/^#?[a-zA-Z_]+\.UTF-8/{print $1}' | sed 's/^[^#]/on &/' | sed 's/^#/off /' | awk '{print $2 " " $1}' ) )
  unset IFS


  dialog \
      --backtitle "${BACKTITLE}" \
      --title "Locales to generate" \
      --insecure \
      --visit-items \
      --no-items \
      --separate-output \
      --checklist "" \
  25 50 20 \
    ${LOCALES_LIST[@]} \
   2>"${TMPDIR}${CONFIGNAME}.${SFX}"

  RES=$?

  CHOSEN_LOCALES_LIST=( $( get_saved_params "${SFX}" | sed 's/en_US.UTF-8/& on/' | sed 's/^[^[:space:]]*$/& off/' ) )
  exec 3>&1
  DEF_LOCALE=$(  dialog \
      --backtitle "${BACKTITLE}" \
      --title "Default locale" \
      --no-items \
      --radiolist "" \
  15 50 15 \
    ${CHOSEN_LOCALES_LIST[@]} \
    2>&1 1>&3 )
  exec 3>&-

  sed -i "s/${DEF_LOCALE}/+&/" "${TMPDIR}${CONFIGNAME}.${SFX}"

  let RES=RES+$?

  clear

  return $RES
}

select_timezone() {
  SFX=$1

  LOCALES_LIST=( $( timedatectl list-timezones | awk '{print $1 " off"}') )

  dialog \
      --backtitle "${BACKTITLE}" \
      --title "Timezone" \
      --visit-items \
      --no-items \
      --radiolist "" \
  25 50 20 \
    ${LOCALES_LIST[@]} \
   2>"${TMPDIR}${CONFIGNAME}.${SFX}"

  RES=$?

  clear

  return $RES
}

select_bootloader() {
  SFX=$1

  dialog \
      --backtitle "${BACKTITLE}" \
      --title "Bootloader" \
      --yesno "Would you like to install Grub bootloader?" 0 0

  RES=$?
  if [ $RES -eq 0 ]; then
    dev=$( get_saved_params "1" )
    BOOT_DISK=$( lsblk -plno PKNAME,NAME | grep "${dev}" | awk '{print $1}' )
  else
    BOOT_DISK=0
  fi
  echo "${BOOT_DISK}" > "${TMPDIR}${CONFIGNAME}.${SFX}"
  clear

  return $RES
}

format_all_params() {
  # device
  dev=$( get_saved_params "1" )
  # user_params
  userParams=$( get_saved_params "2" )
  i=0
  while read line; do
    userParams[$i]="$line"
    (( i++ ))
  done < <( get_saved_params "2" )
  comp=${userParams[0]}
  user=${userParams[1]}
  psw=${userParams[2]}
  psw2=${userParams[3]}

  # locale
  localesList=$( get_saved_params "3" | sed 's/^+//' | tr "\n" ", " | sed 's/,$//' )
  defLocale=$( get_saved_params "3" | awk '/^+/{print $0}' | sed 's/^+//')
  # timezone
  tz=$( get_saved_params "4" )
  # bootloader
  BOOT_DISK=$( get_saved_params "5" )
  if [ "$BOOT_DISK" = "0" ]; then
    useGrub="no"
  else
    useGrub="yes (to ${BOOT_DISK})"
  fi

  echo "Just finished to collect settings for installation.

Settings to be apllied are:

Root device:          ${dev:-"n/a"}
Computer name:        ${comp:-"n/a"}
Username:             ${user:-"n/a"}
Locales to generate:  ${localesList:-"n/a"}
Default locale:       ${defLocale:-"n/a"}
Timezone:             ${tz:-"n/a"}
Install GRUB2:        ${useGrub:-"n/a"}


Do you want to proceed with install?"
}

confirm_install() {
  MSG_TEXT="$( format_all_params )"
  dialog \
    --backtitle "${BACKTITLE}" \
    --no-collapse \
    --cr-wrap \
    --title "Confirm settings" \
    --yesno "${MSG_TEXT}" 0 0
  return $?
}

do_reboot() {
    dialog \
    --backtitle "${BACKTITLE}" \
    --no-collapse \
    --cr-wrap \
    --title "Reboot now?" \
    --yesno "${MSG_TEXT}" 0 0
  if [ $? -eq 0 ]; then
    reboot
  fi
}

set_lang_settings() {

  rootDir=$1

  SFX=$2

  # get locale settings
  localesList=$( get_saved_params "${SFX}" | sed 's/^+//' )
  defLocale=$( get_saved_params "${SFX}" | awk '/^+/{print $0}' | sed 's/^+//' )

  # enable every chosen locale
  for loc in $localesList; do
    sed -i "s/^#${loc}/${loc}/" $rootDir/etc/locale.gen
  done
  # generate enabled locales
  arch-chroot $rootDir locale-gen

  # set default in /etc/locale.conf
  # LC_NUMERIC is set to en_US.UTF-8 - need for "." on numpad instead of "," on some locales
  echo "LANG=\"${defLocale}\"" >$rootDir/etc/locale.conf
  echo "LC_NUMERIC=\"en_US.UTF-8\"" >>$rootDir/etc/locale.conf

  # TODO: localize obmenu
  # make language suffixed schema_<lang>.pl and create schema.pl as symlink to apropriate schema
  # fallback lang is english (en)
}


do_install() {

  #--------------------------------
  # ONCE AGAIN READ ALL SETTINGS
  #--------------------------------
  # device
  dev=$( get_saved_params "1" )
  # user_params
  userParams=$( get_saved_params "2" )
  i=0
  while read line; do
    userParams[$i]="$line"
    (( i++ ))
  done < <( get_saved_params "2" )
  comp=${userParams[0]}
  user=${userParams[1]}
  psw=${userParams[2]}
  psw2=${userParams[3]}

  # locale
  localesList=$( get_saved_params "3" | sed 's/^+//' | tr "\n" ", " | sed 's/,$//' )
  defLocale=$( get_saved_params "3" | awk '/^+/{print $0}' | sed 's/^+//' )
  # timezone
  tz=$( get_saved_params "4" )
  # bootloader
  BOOT_DISK=$( get_saved_params "5" )
  #if [ "$BOOT_DISK" = "0" ]; then
    # install_grub
  #fi
  #--------------------------------

  #--------------------------------
  # BEGIN INSTALL
  #--------------------------------
  # ------ Try to mount new root ------
  mount_new_root "${dev}" "/mnt"
  RES=$?
  if [ "$RES" -ne 0 ]; then
    display_info "Failed to mount new root (errcode ${RES})"
    return 3
  fi

  # ------ Copy files to new root ------
  copy_to_new_root "/mnt"
  RES=$?
  if [ "$RES" -ne 0 ]; then
    display_info "Failed to copy to new root"
    return 4
  fi

  # ------ copy the kernel image to the new root ------
  cp -vaT /run/archiso/bootmnt/arch/boot/$(uname -m)/vmlinuz /mnt/boot/vmlinuz-linux 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Copying kernel image..." \
    --progressbox 10 70


  # TODO: swap?

  # ------ generate a fstab ------
  genfstab -U "/mnt" > /mnt/etc/fstab 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Generating fstab..." \
    --progressbox 10 70

  # ------ Create an initial ramdisk environment ------
  arch-chroot "/mnt" mkinitcpio -p linux 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Creating an initial ramdisk environment..." \
    --progressbox 10 70

  # ------ Set personal information ------
  arch-chroot "/mnt" $SCRIPT_DIR/include/set_user_params.sh "${comp}" "${user}" "${psw}" 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Setting personal information" \
    --progressbox 10 70

  # ------ Set language ------
  set_lang_settings "/mnt" "3" 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Setting up language" \
    --progressbox 10 70

  # ------ Installing bootloader ------
  install_grub "/mnt" "${dev}" 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Installing bootloader..." \
    --progressbox 10 70

  # ------ Removing live environment trails ------
  remove_live_trails "/mnt" 2>&1 | dialog \
    --backtitle "${BACKTITLE}" \
    --title "Removing live environment trails..." \
    --progressbox 10 70
}
