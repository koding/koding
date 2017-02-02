#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

export GOPATH=${GOPATH:-$(pwd)/go}

echo "checking with gometalinter"
# use specific folders like socialapi & koding instead of $GOPATH/src/...
# otherwise it will check all paths like vendors, github, gopkg etc..
go/bin/gometalinter.v1 --concurrency=5 --config="$GOPATH/src/.gometalinter.json" $GOPATH/src/socialapi/... $GOPATH/src/koding/... --deadline=10s | grep -v /vendor/
