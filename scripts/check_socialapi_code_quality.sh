#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

v=$(git diff-tree -r --name-only --no-commit-id master `git rev-parse HEAD` ./go/src/socialapi 2>&1)
if [ -z "$v" ]; then
    echo "nothing has changed under ./go/src/socialapi"
    exit 0
fi



echo "checking cyclo complexity"
./go/bin/gocyclo -top 20 ./go/src/socialapi/*/**/**.go

echo "checking deadcode"
./scripts/deadcode.sh

echo "checking go vet"
#./scripts/govet.sh

echo "checking unused variables"
./scripts/govarcheck.sh
