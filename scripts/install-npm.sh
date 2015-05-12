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

  npm install $NPM_ARGS
}

NPM_ARGS=

while getopts ":d:us" OPTION; do
  case $OPTION in
    d) WORKING_DIR=$OPTARG ;;
    u) NPM_ARGS+=" --unsafe-perm" ;;
    s) NPM_ARGS+=" --silent" ;;
  esac
done

install
