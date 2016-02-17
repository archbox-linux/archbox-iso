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


set_lang_settings
