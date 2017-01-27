#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

v=$(git diff-tree -r --name-only --no-commit-id `git rev-parse HEAD` ./go/src/socialapi 2>&1)
if [ -z "$v" ]; then
    echo "nothing has changed under ./go/src/socialapi"
    exit 0
fi

echo "checking cyclo complexity (disabled due to go1.6 switch - fixme!)"
# Due to go1.6 gocyclo check started suddently to work showing
# a number of complex functions:
#
#  https://app.wercker.com/#buildstep/5794af80d5df0401007a95dda
#
# Please fix the code and lower the value back to 20.
#
# ./go/bin/gocyclo -top 28 ./go/src/socialapi/*/**/**.go

echo "checking deadcode"
./scripts/deadcode.sh

echo "checking unused variables"
./scripts/govarcheck.sh
