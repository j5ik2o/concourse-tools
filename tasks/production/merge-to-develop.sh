#!/bin/bash

set -ex

source tool-repo/tasks/common.sh

HOME=/root
git_config

cd api-repo

git pull origin ${PRODUCTION_BRNCH}

LOG=$(git_log)
echo -e "$LOG" > ../notify-message/text

cd ..

git clone api-repo updated-api-repo

echo "merge to develop from master"
exit 0
