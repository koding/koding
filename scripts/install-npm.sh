#!/bin/bash

install()
{
  REF=`dirname $0`
  BASEDIR=`cd $REF/.. && pwd -P`
  TARGET=${BASEDIR}/${RELATIVE_DIR}
  if [ -d $TARGET ]
  then
    echo -e "\033[0;32m${RELATIVE_DIR}\033[0m: verifying npm dependencies"
    npm --prefix $TARGET ls > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
      echo -e "\033[0;33m${RELATIVE_DIR}\033[0m: installing npm dependencies"
      npm install --prefix $TARGET $NPM_ARGS
    else
      if [ ! -z $FORCE_PREINSTALL ]
      then
        echo -e "\033[0;34m${RELATIVE_DIR}\033[0m: running npm preinstall script"
        npm run preinstall --prefix $TARGET $NPM_ARGS
      fi
    fi
  else
    echo -e "\033[0;31merror\033[0m: install-npm failed, $TARGET does not exist"
  fi
}

NPM_ARGS=

while getopts ":d:usp" OPTION; do
case $OPTION in
d) RELATIVE_DIR=$OPTARG;;
u) NPM_ARGS+=" --unsafe-perm";;
s) NPM_ARGS+=" --silent";;
p) FORCE_PREINSTALL=TRUE;;
esac
done

if [ ! -z $RELATIVE_DIR ]
then
  install $RELATIVE_DIR
fi
