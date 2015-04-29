#!/bin/bash

install()
{
  REF=`dirname $0`
  BASEDIR=`cd $REF/.. && pwd -P`
  TARGET=${BASEDIR}/${RELATIVE_DIR}

  if [ ! -d $TARGET ]; then
    echo -e "\033[0;31merror\033[0m: install-npm failed, $TARGET does not exist"
    exit 1
  fi

  echo -e "\033[0;32m${RELATIVE_DIR}\033[0m: verifying npm dependencies"
  npm --prefix $TARGET ls > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    exit 0
  fi

  echo -e "\033[0;33m${RELATIVE_DIR}\033[0m: installing npm dependencies"
  npm install --prefix $TARGET $NPM_ARGS
}

NPM_ARGS=

while getopts ":d:usp" OPTION; do
  case $OPTION in
    d) RELATIVE_DIR=$OPTARG ;;
    u) NPM_ARGS+=" --unsafe-perm" ;;
    s) NPM_ARGS+=" --silent" ;;
  esac
done

install $RELATIVE_DIR
