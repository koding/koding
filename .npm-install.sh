#!/bin/bash

set -o errexit

scripts/patch-node-modules.sh

pushd client
npm install
popd
