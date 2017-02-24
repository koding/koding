#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

export GOPATH=${GOPATH:-$(pwd)/go}

echo "checking with gometalinter"
go get gopkg.in/alecthomas/gometalinter.v1/...
# use specific folders like socialapi & koding instead of $GOPATH/src/...
# otherwise it will check all paths like vendors, github, gopkg etc..
go/bin/gometalinter.v1 --config="$GOPATH/src/.gometalinter.json" $GOPATH/src/socialapi/... $GOPATH/src/koding/...
