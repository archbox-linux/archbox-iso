#!/usr/bin/bash

ROOT_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )

# setting owner to root
sudo chown -R root:root $ROOT_DIR/archbox/*

# reset work dir
sudo rm -v $ROOT_DIR/archbox/work/build.make_*

# copy fresh version of installer to airootfs
sudo mkdir -p $ROOT_DIR/archbox/airootfs/opt/archbox
sudo cp $ROOT_DIR/scripts/install.sh $ROOT_DIR/archbox/airootfs/opt/archbox/
sudo cp -r $ROOT_DIR/scripts/include $ROOT_DIR/archbox/airootfs/opt/archbox/
