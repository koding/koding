#!/bin/bash

function check_node_version()
{
  VERSION=`node -v`
  if [ "$VERSION" == "v0.10.33" ]
  then
    echo -e "\033[0;32myou have node $VERSION installed, great\033[0m"
  else
    echo -e "\033[0;31myou have node $VERSION installed, recommended version is v0.10.33\033[0m"
    echo -e "\033[0;31msee nvm, nvm is awesome: https://github.com/creationix/nvm\033[0m"
  fi
}

list_deps()
{
  REF=`dirname $0`
  CLIENT_DIR=${REF}/../${1}
  if [ -d $CLIENT_DIR ]
  then
    CLIENT_DIR=$(cd $(dirname "$1") && pwd -P)/$(basename "$1")
    npm --prefix $CLIENT_DIR ls > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
      echo -e "\033[0;32m$CLIENT_DIR has its npm deps installed, awesome\033[0m"
    else
      echo -e "\033[0;31mmissing npm deps in $CLIENT_DIR\033[0m"
      echo -e "\033[0;31mdo this and ur deps will be ok:\033[0m"
      echo -e "\033[0;31mrm -fr $CLIENT_DIR/node_modules && npm i --prefix $CLIENT_DIR\033[0m"
      exit 1
    fi
  fi
}

echo -e "\033[0;35mverifying client deps, node version and stuff\033[0m"
check_node_version
list_deps client
list_deps client/landing
echo -e "\033[0;35mfinished verifying client deps, node version and stuff\033[0m"
