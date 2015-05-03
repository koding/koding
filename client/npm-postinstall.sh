#!/bin/bash

set -o errexit

cd $(dirname $0)

UPDATE_WERCKER_NODE_MODULES=../scripts/wercker/update-node-modules

if [ "$CI" = "true" -a "$WERCKER" = "true" ]; then
  $UPDATE_WERCKER_NODE_MODULES
  $UPDATE_WERCKER_NODE_MODULES builder
  $UPDATE_WERCKER_NODE_MODULES landing
fi

exit 0
