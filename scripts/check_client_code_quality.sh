#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

path="./client/teams"

v=$(git diff-tree -r --name-only --no-commit-id master `git rev-parse HEAD` $path 2>&1)
if [ -z "$v" ]; then
    echo "nothing has changed under $path"
    exit 0
fi

echo "checking unused variables"
path=$path ./scripts/coffeevarcheck.sh
