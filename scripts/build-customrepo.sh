#!/usr/bin/bash

if [ "s$( id -u )" = "s0" ]; then
  echo "You shouldn't run it under root"
  exit
fi

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

#TODO: check devtools and install it (if needed) to build in clean chroot

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
        if [ "_$srcDir" == "_pamac-aur" ] ; then
           echo -n "Fixing pamac-aur architecture..."
           sed -i "s/arch=('any')/arch=('i686' 'x86_64')/" "PKGBUILD"
           echo "done!"
         fi

        #build package for 32bit arch
        makechrootpkg -r "$REPO_DIR/chroot/i686" -- -i || exit 1
        # move package to customrepo
        #find "$REPO_DIR/build" -name "*.pkg.tar.xz" -exec mv {} "$REPO_DIR/i686/" \;
        echo "Finished building 32 bit package"

        #build package for 64bit arch
        makechrootpkg -r "$REPO_DIR/chroot/x86_64" -- -i || exit 1
        # move package to customrepo
        #find "$REPO_DIR/build" -name "*.pkg.tar.xz" -exec mv {} "$REPO_DIR/x86_64/" \;
        echo "Finished building 64 bit package"

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

#prepare customrepo
mkdir -p "$REPO_DIR/i686"
mkdir -p "$REPO_DIR/x86_64"

build_package_list "packages-aur.lst"
build_package_list "packages-local.lst"


# copy packages to customrepo
# *-i686.pkg.tar.xz - to i686
# *-x86_64.pkg.tar.xz - to x86_64
# *-any.pkg.tar.xz - to both i686 and x86_64
find "$REPO_DIR/build" -name "*-i686.pkg.tar.xz" -exec cp {} "$REPO_DIR/i686/" \;
find "$REPO_DIR/build" -name "*-x86_64.pkg.tar.xz" -exec cp {} "$REPO_DIR/x86_64/" \;
find "$REPO_DIR/build" -name "*-any.pkg.tar.xz" -exec cp {} "$REPO_DIR/i686/" \;
find "$REPO_DIR/build" -name "*-any.pkg.tar.xz" -exec cp {} "$REPO_DIR/x86_64/" \;

# add packages to repo db
cd "$REPO_DIR/i686/"
repo-add ./customrepo.db.tar.gz ./*.pkg.tar.xz
cd "$REPO_DIR/x86_64/"
repo-add ./customrepo.db.tar.gz ./*.pkg.tar.xz

cd "$ROOT_DIR"

# NEW ALGORITM
# remove [customrepo] unconditionally
# this is better way because we can insert then in right place (even if it wasn`t there)
# (customrepo must be the first repo in pacman.conf for higher priority)
# and also no need separate procedures of inserting and inplace editing

# delete lines from line containing "customrepo" up to first empty line
sed -i '/customrepo/,/^$/d' ./archbox/pacman.conf

# find all [<string>] sections beginings
for sec in $( egrep -o "^\[[^]]+]$" ./archbox/pacman.conf ); do
# get first section ignoring [options] section
  if [ "s$sec" = "s[options]" ]; then continue; fi
# define line number of first repo section
#                            | remove [ and ]        |
  REPO_LINE=$( echo "${sec}" | sed -E 's/(\[|\])//g' | xargs -I== egrep -on "^\[==\]$" ./archbox/pacman.conf | awk -F ":" '{print $1}' )
  break;
done

# insert customrepo section:
#   [customrepo]
#   SigLevel = Optional TrustAll
#   Server = file://<full-path-to-archbox-profile>/customrepo/$arch
  sed -i "${REPO_LINE}"'i[customrepo]\
SigLevel = Optional TrustAll\
Server = file://'"${REPO_DIR}"'/$arch\
' ./archbox/pacman.conf

echo "DONE!"
