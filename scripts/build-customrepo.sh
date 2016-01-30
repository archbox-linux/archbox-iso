#!/usr/bin/bash

ROOT_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )
REPO_DIR="$ROOT_DIR/customrepo"

if [ ! -d "$REPO_DIR/build" ]; then
  mkdir "$REPO_DIR/build"
fi

cd "$REPO_DIR/build"

#download packages from aur
cat $REPO_DIR/packages-aur.lst | xargs yaourt -G

echo "copying theme"
cp -r "$ROOT_DIR/artwork/themes/numix-themes-hreen" .

#check devtools and install it (if needed) to build in clean chroot

if [ ! -d "$REPO_DIR/chroot" ]; then
  mkdir "$REPO_DIR/chroot"
fi

while read srcDir; do
    echo "Package $srcDir"
    if [ -d $srcDir ] && [ -f "$srcDir/PKGBUILD" ] ; then
      echo "Enter to $srcDir"
      cd "$srcDir"
      #build package for 32bit arch
      extra-i686-build -r $REPO_DIR/chroot
      echo "Finished building 32 bit package"
      #build package for 64bit arch
#      extra-x86_64-build -r $REPO_DIR/chroot
      
      echo "Return to build dir"
      cd "$REPO_DIR/build"
    fi
done <"$REPO_DIR/packages-aur.lst"

#for srcDir in *; do
#    if [ -d $srcDir ] && [ -f "$srcDir/PKGBUILD" ] ; then
#      cd "$srcDir"
#      #build package for 32bit arch
#      extra-i686-build -r $REPO_DIR/chroot
#      #build package for 64bit arch
##      extra-x86_64-build -r $REPO_DIR/chroot
#    fi
#done

