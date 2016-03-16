#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

if [[ -z "$src" ]]; then
    src=./client
fi

v=$(node ./node_modules/coffee-unused --src $src --skip-parse-error)
if [ -n "$v" ]; then
    #log it
    echo $v
    exit 1
fi
