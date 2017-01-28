#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

path="./client"

git diff-tree -r --exit-code --name-only --no-commit-id HEAD \
    client && exit 0

echo "checking unused variables"
path=$path ./scripts/coffeevarcheck.sh
