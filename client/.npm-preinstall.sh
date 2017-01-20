#!/bin/bash

set -o errexit

cd $(dirname $0)

INSTALL_WERCKER_NODE_MODULES=../scripts/wercker/install-node-modules

if [ "$CI" = "true" -a "$WERCKER" = "true" ]; then
  $INSTALL_WERCKER_NODE_MODULES client
  $INSTALL_WERCKER_NODE_MODULES landing landing
fi

pushd landing
npm install
popd
