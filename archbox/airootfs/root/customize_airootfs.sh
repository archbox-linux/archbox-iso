#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root

USER=archbox

# create user
! id $USER && useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel" -s /usr/bin/zsh $USER
# set user password (same as username)
echo "$USER:$USER" | chpasswd
# add permissions to execute as root to wheel group (asking a password)
#! grep "^[[:space:]]*%wheel[[:space:]]ALL=(ALL)[[:space:]].*ALL" /etc/sudoers && echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-wheel-nopassword

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

systemctl enable pacman-init.service choose-mirror.service
systemctl set-default graphical.target

systemctl enable NetworkManager

#customize grub theme (affects only target installed system - grub defaults will be copied while installing)
#sed -i "/#GRUB_THEME=/d; s/^GRUB_THEME=.*$/GRUB_THEME=\"\/usr\/share\/themes\/archbox\/theme\.txt\"/" /etc/default/grub
sed -i "/#*GRUB_THEME=/d" /etc/default/grub
echo 'GRUB_THEME="/usr/share/themes/archbox/theme.txt"' >> /etc/default/grub
