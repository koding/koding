#!/bin/bash

function check_node_version()
{
  VERSION=`node -v`
  if [ "$VERSION" != "v0.10.33" ]
  then
    echo -e "\033[0;33mwarning: \033[0myou have node $VERSION installed, recommended version is v0.10.33"
  fi
}

function check_npm_version()
{
  VERSION=`npm -v`
  if [ "${VERSION:0:1}" == "1" ]
  then
    echo -e "\033[0;33mwarning: \033[0myou have npm v$VERSION installed, recommended version is v2.x"
  fi
}

check_node_version
check_npm_version
