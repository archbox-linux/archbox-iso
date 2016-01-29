#!/usr/bin/bash

ROOT_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )
REPO_DIR="$ROOT_DIR/customrepo"

if [ ! -d "$REPO_DIR/build" ]; then
  mkdir "$REPO_DIR/build"
fi

cd "$REPO_DIR/build"

cat ./packages-local.lst | xargs yaourt -G
