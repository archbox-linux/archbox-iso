#!/bin/bash

#export DE=openbox

includes=/etc/X11/xinit/xinitrc.d
if [ -d "$includes" ]; then
  for f in "$includes/"*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi
unset includes

# Dbus fix
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

/usr/bin/xdg-user-dirs-update

/usr/bin/openbox-session > ~/.openbox_startup.log 2>&1

