#!/bin/bash

set -ex

source tool-repo/tasks/common.sh

HOME=/root
git_config

BUILD_CACHE_DIR=application-build-cache
ROOT_FS_DIR=$BUILD_CACHE_DIR/rootfs
SBT_BOOT_DIR=$ROOT_FS_DIR/opt/sbt-boot
SBT_IVY_DIR=$ROOT_FS_DIR/opt/sbt-ivy

cd api-repo

git symbolic-ref HEAD refs/heads/${PRODUCTION_BRNCH}

cat version.sbt

LOG=$(git_log)
echo -e "$LOG" > ../notify-message/text

sbt \
    -DTEST_TIME_FACTOR=10 \
    -Dsbt.boot.directory=../$SBT_BOOT_DIR \
    -Dsbt.ivy.home=../$SBT_IVY_DIR \
    'release with-defaults'

cp -Rp ${SBT_TARGET_DOCKER_PATH}/* ../to-push/
cp -p target/tag ../to-push/

cd ..

git clone version-repo updated-version-repo
cat api-repo/target/tag > updated-version-repo/VERSION

VERSION=$(cat updated-version-repo/VERSION)

cat << EOT >> notify-message/text
tag: $VERSION
EOT


cd updated-version-repo
git add VERSION
git commit -m "updated version to ${VERSION}"

echo "build docker and publish"
exit 0
