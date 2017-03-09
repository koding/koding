#!/bin/bash
SHA=$(cat /var/app/current/VERSION || git rev-parse --short HEAD || echo "0")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
NAME=$1
MESSAGE=$2
STATUS=$3
PERCENTAGE=$4

ENV_NAME="CI"

if [ ! -n "$EB_ENV_NAME" ]; then
	ENV_NAME=$EB_ENV_NAME
fi

curl -s --connect-timeout 2 -X POST -d "name=$NAME&sha=$SHA&message=$MESSAGE&status=$STATUS&percentage=$PERCENTAGE&branch=$BRANCH&env=$ENV_NAME" $CEBECI_WERCKER_ENDPOINT >>/dev/null

exit 0
