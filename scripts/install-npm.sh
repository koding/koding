#!/bin/bash

install()
{
  if [ -n "$WORKING_DIR" ]; then
    if [ ! -d $WORKING_DIR ]; then
      echo -e "\033[0;31merror\033[0m: install-npm failed, $WORKING_DIR does not exist"
      exit 1
    fi

    cd $WORKING_DIR
  else
    WORKING_DIR=$(basename $(pwd))
  fi

  echo -e "\033[0;32m${WORKING_DIR}\033[0m: verifying npm dependencies"
  npm ls > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    exit 0
  fi

  echo -e "\033[0;33m${WORKING_DIR}\033[0m: installing npm dependencies"
  npm install $NPM_ARGS
}

NPM_ARGS=

while getopts ":d:usp" OPTION; do
  case $OPTION in
    d) WORKING_DIR=$OPTARG ;;
    u) NPM_ARGS+=" --unsafe-perm" ;;
    s) NPM_ARGS+=" --silent" ;;
  esac
done

install
