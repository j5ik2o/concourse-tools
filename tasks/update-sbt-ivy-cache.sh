#!/bin/sh

set -ex

source tool-repo/tasks/common.sh

BUILD_CACHE_DIR=astraea-build-cache
ROOT_FS_DIR=$BUILD_CACHE_DIR/rootfs
SBT_BOOT_DIR=$ROOT_FS_DIR/opt/sbt-boot
SBT_IVY_DIR=$ROOT_FS_DIR/opt/sbt-ivy

if [ ! -e $BUILD_CACHE_DIR ]; then
  mkdir -p $SBT_BOOT_DIR
  mkdir -p $SBT_IVY_DIR
fi

cd api-repo

sbt \
  -Dsbt.boot.directory=../$SBT_BOOT_DIR \
  -Dsbt.ivy.home=../$SBT_IVY_DIR \
  test:compile

cd ..

cd $BUILD_CACHE_DIR
tar -C rootfs -cf rootfs.tar .
mv rootfs.tar ../to-push

echo "update sbt ivy cache"
exit 0
