#ArchBox

ArchBox means Arch Linux + Openbox

This project contains [archiso](https://wiki.archlinux.org/index.php/archiso) profile to build ready-to-use iso with [Arch Linux](https://www.archlinux.org/) and preconfigured [Openbox](http://openbox.org) window manager.

For now it is just a live media. In plans - with ability to install.

###Prerequisites:
Arch Linux (x64_86), installed archiso, packages from base-devel group (?), yaourt (link here)

##Build iso

1. Clone this git repo 
    (TODO: insert git command here)

2. Change dir to ./scripts/

3. run build-customrepo.sh (as normal user)
    this will build all packages from AUR needed to include to iso (listed in packages-aur.lst) and add repo record to pacman.conf
    Hint: may need to enter root password for sudo
    Warning! This needs to build it in a clean chroot (TODO: link here to archwiki about building in chroot) so will take quite a lot of disk space (~4Gb).

4. run prepare-build.sh
    this change owner of profile dir to root and clean up work dir in case of iso rebuild

5. cd to "./archbox" and run "./build.sh -v" as root
