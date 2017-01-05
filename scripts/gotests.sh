#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

export COMPILE_FLAGS=${COMPILE_FLAGS:-""}

if [ "$1" == "test_socialapi" ]; then
  shift
  confPath="-c="$(pwd)"/go/src/socialapi/config/dev.toml"
  # export RUN_FLAGS="$RUN_FLAGS $confPath"
  # TODO
  # If there is more than 1 argument for run flag config file + another flag
  # then there is an error in bash script
  export RUN_FLAGS="$confPath"
  echo $RUN_FLAGS

  ./scripts/gotest.sh $@
  unset COMPILE_FLAGS

elif [ "$1" == "gotest" ]; then
  shift
  ./scripts/gotest.sh $@
fi
