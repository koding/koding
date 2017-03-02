#!/bin/bash

set -o errexit

pushd $(dirname $0)

touch node_modules/.npm-install.timestamp

[ -z "$CI" ] && exit 0

[ $(git rev-parse --abbrev-ref HEAD) != "master" ] && exit 0

UPDATE_WERCKER_NODE_MODULES=../scripts/wercker/update-node-modules

$UPDATE_WERCKER_NODE_MODULES
$UPDATE_WERCKER_NODE_MODULES landing

popd

exit 0
