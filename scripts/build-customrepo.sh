#!/usr/bin/bash

ROOT_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )
REPO_DIR="$ROOT_DIR/customrepo"
ARCH=both

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
  mkdir -p "$REPO_DIR/chroot"
fi

makechroot() {
  local arch=$1
  mkdir -p "$REPO_DIR/chroot/${arch}"
  setarch "${arch}" mkarchroot \
           -C "/usr/share/devtools/pacman-extra.conf" \
           -M "/usr/share/devtools/makepkg-${arch}.conf" \
           "$REPO_DIR/chroot/${arch}/root" \
           "base-devel" || exit 1
  return 0;
}

build_package_list() {
  local package_list=$1

  while read srcDir; do
      echo "Package $srcDir"
      if [ -d "$srcDir" ] && [ -f "$srcDir/PKGBUILD" ] ; then
        echo "Enter to $srcDir"
        cd "$srcDir"

        #temporary fix for pamac-aur
        #if [ "_$srcDir" == "_pamac-aur" ] ; then
        #  echo -n "Fixing pamac-aur..."
        #  sed -i 's/dabd01fc2315fecd01c85de040bf97f4ba3932343590fa06a95d0a324554d089/749d9d153fbbe5b3709423983a6da6dfafae16a09acf8ccb6d35427f47cb804a/' "PKGBUILD"
        #  echo "done!"
        #fi

        #build package for 32bit arch
        makechrootpkg -r "$REPO_DIR/chroot/i686" -- -i || exit 1
        echo "Finished building 32 bit package"

        #build package for 64bit arch
        makechrootpkg -r "$REPO_DIR/chroot/x86_64" -- -i || exit 1
        echo "Finished building 32 bit package"

        echo "Return to build dir"
        cd "$REPO_DIR/build"
      fi
  done <"$REPO_DIR/$package_list"
}

#prepare chroot
if [ "s$ARCH" == "s32" ] || [ "s$ARCH" == "sboth" ] ; then
  if ! [ -d "$REPO_DIR/chroot/i686/root" ] ; then
    echo "Making chroot (i686)"
    makechroot "i686"
  fi
fi

if [ "s$ARCH" == "s64" ] || [ "s$ARCH" == "sboth" ] ; then
  if ! [ -d "$REPO_DIR/chroot/x86_64/root" ] ; then
    echo "Making chroot (x86_64)"
    makechroot "x86_64"
  fi
fi

build_package_list "packages-aur.lst"
build_package_list "packages-local.lst"

#prepare customrepo
mkdir -p "$REPO_DIR/i686"
mkdir -p "$REPO_DIR/x86_64"

# copy packages to customrepo
# *-i686.pkg.tar.xz - to i686
# *-x86_64.pkg.tar.xz - to x86_64
# *-any.pkg.tar.xz - to both i686 and x86_64
find "$REPO_DIR/build" -name "*-i686.pkg.tar.xz" -exec cp {} "$REPO_DIR/i686/" \;
find "$REPO_DIR/build" -name "*-x86_64.pkg.tar.xz" -exec cp {} "$REPO_DIR/x86_64/" \;
find "$REPO_DIR/build" -name "*-any.pkg.tar.xz" -exec cp {} "$REPO_DIR/i686/" \;
find "$REPO_DIR/build" -name "*-any.pkg.tar.xz" -exec cp {} "$REPO_DIR/x86_64/" \;

cd "$REPO_DIR/i686/"
repo-add ./customrepo.db.tar.gz ./*.pkg.tar.xz
cd "$REPO_DIR/x86_64/"
repo-add ./customrepo.db.tar.gz ./*.pkg.tar.xz

echo "DONE!"
