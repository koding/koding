#!/bin/bash
version=$(cat /var/app/current/VERSION || echo $WERCKER_GIT_COMMIT || echo "0")

SHA=${version:0:8}
BRANCH=$WERCKER_GIT_BRANCH
NAME=$1
MESSAGE=$2
STATUS=$3
PERCENTAGE=$4

ENV_NAME="wercker"

if [ ! -n "$EB_ENV_NAME" ]; then
  ENV_NAME=$EB_ENV_NAME
fi

curl -s --connect-timeout 2 -X POST -d "name=$NAME&sha=$SHA&message=$MESSAGE&status=$STATUS&percentage=$PERCENTAGE&branch=$BRANCH&env=$ENV_NAME" http://cebeci.koding.com/cebeci/hook/wercker/incoming >> /dev/null

exit 0
