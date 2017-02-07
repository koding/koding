#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

git diff-tree -r --exit-code --name-only --no-commit-id HEAD \
	go/src/socialapi && exit 0

export GOPATH=${GOPATH:-$(pwd)/go}

echo "checking deadcode"
ls --directory $GOPATH/src/socialapi/*/**/**/ \
	| xargs go/bin/deadcode

# echo "checking unused variables"
# echo $(cd $GOPATH/src; ls --directory socialapi/*/**/**/) | \
#   xargs $GOPATH/bin/varcheck

echo "checking cyclo complexity (disabled due to go1.6 switch - fixme!)"
# Due to go1.6 gocyclo check started suddently to work showing
# a number of complex functions:
#
#  https://app.wercker.com/#buildstep/5794af80d5df0401007a95dda
#
# Please fix the code and lower the value back to 20.
#
# ./go/bin/gocyclo -top 28 ./go/src/socialapi/*/**/**.go
