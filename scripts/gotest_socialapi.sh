#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

confPath="-c="$(pwd)"/go/src/socialapi/config/dev.toml"
export RUN_FLAGS=${RUN_FLAGS:-$confPath}

./scripts/gotest.sh $@
