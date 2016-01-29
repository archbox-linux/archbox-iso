#!/usr/bin/bash

ROOT_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )

# setting owner to root
chown -R root:root $ROOT_DIR/archbox/*

# reset work dir
rm -v $ROOT_DIR/archbox/work/build.make_*

source ./build-customrepo.sh

