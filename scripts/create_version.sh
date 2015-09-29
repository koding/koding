#!/bin/bash

# this script checks the environment name acts according to it, will be only
# used in EB envs
#
# if latest, uses the latest-deployment tag's sha
# if production, uses the latest-deployment tag's sha
# else: just use the standart git rev
if [ "$CONFIG" == "latest" ]; then
    git checkout latest-deployment
fi

if [ "$CONFIG" == "prod" ]; then
    git checkout production-deployment
fi

version=$(git rev-parse HEAD)

SHA=${version:0:8}

# output version file
echo $SHA > $WERCKER_ROOT/VERSION

# output archive name, that will be used for version archive name
echo `date "+%Y-%m-%dT%H:%M:%S"`_$SHA.zip > $WERCKER_ROOT/ARCHIVE_NAME

