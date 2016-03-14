#!/bin/bash

set -o errexit

[ "$CI" != "true" -o "$WERCKER" != "true" ] && exit 0

[ "$WERCKER_GIT_REPOSITORY" != "koding" ] && exit 0
[ "$WERCKER_GIT_BRANCH" != "master" ] && exit 0

cd $(dirname $0)

UPDATE_WERCKER_NODE_MODULES=../scripts/wercker/update-node-modules

$UPDATE_WERCKER_NODE_MODULES
$UPDATE_WERCKER_NODE_MODULES builder
$UPDATE_WERCKER_NODE_MODULES landing

exit 0
