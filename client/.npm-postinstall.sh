#!/bin/bash

set -o errexit

pushd $(dirname $0)

touch node_modules/.npm-install.timestamp

[ "$CI" != "true" -o "$WERCKER" != "true" ] && exit 0

[ "$WERCKER_GIT_REPOSITORY" != "koding" ] && exit 0
[ "$WERCKER_GIT_BRANCH" != "master" ] && exit 0

UPDATE_WERCKER_NODE_MODULES=../scripts/wercker/update-node-modules

$UPDATE_WERCKER_NODE_MODULES
$UPDATE_WERCKER_NODE_MODULES landing

popd

exit 0
