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

LOG=$(git_log)
echo -e "$LOG" > ../notify-message/text

if [ ! -z "${SBT_TEST_CMD}" ]; then
for CMD in ${SBT_TEST_CMD}; do
  sbt \
    -DTEST_TIME_FACTOR=10 \
    -Dsbt.boot.directory=../$SBT_BOOT_DIR\
    -Dsbt.ivy.home=../$SBT_IVY_DIR \
    ${CMD}
done
fi

SBT_CMD="${SBT_BUILD_PROJECT}docker:stage outputVersion"
sbt \
    -Dsbt.boot.directory=../$SBT_BOOT_DIR\
    -Dsbt.ivy.home=../$SBT_IVY_DIR \
    ${SBT_CMD}

cp -Rp ${SBT_TARGET_DOCKER_PATH}/* ../to-push/
cp -p target/tag ../to-push/

cd ..

git clone version-repo updated-version-repo
cat api-repo/target/tag > updated-version-repo/VERSION

VERSION=$(cat updated-version-repo/VERSION)

cat << EOT >> notify-message/text
tag: $VERSION
EOT

set +e
cd updated-version-repo
git add VERSION
git commit -m "updated version to ${VERSION}"
set -e

echo "build docker and publish"
exit 0
