#!/usr/bin/bash

# assuming we are under chroot

comp=$1
user=$2
psw=$3

echo "Setting computer name..."
echo -n "${comp}" > "/etc/hostname"

# ------ Creating user ------
! id $user && useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel" -s /usr/bin/zsh $user

# set user password
echo "$user:$psw" | chpasswd


# disable slim autologin
sed -i "s/^default_user.*$/#default_user\t\t$user}/" /etc/slim.conf
