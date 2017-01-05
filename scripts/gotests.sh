#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

echo "current $1 $2"

export COMPILE_FLAGS=${COMPILE_FLAGS:-""}

if [ "$1" == "test_socialapi" ]; then
  shift
  confPath="-c="$(pwd)"/go/src/socialapi/config/dev.toml"
  export RUN_FLAGS="$RUN_FLAGS $confPath"
  echo $RUN_FLAGS
  ./scripts/gotest.sh $@
  unset COMPILE_FLAGS

elif [ "$1" == "gotest" ]; then
  shift
  ./scripts/gotest.sh $@
fi
