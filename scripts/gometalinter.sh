#!/bin/bash

set -o errexit

export GOPATH=${GOPATH:-$(pwd)/go}
export PATH=$GOPATH/bin:$PATH

go get github.com/gordonklaus/ineffassign
go get github.com/client9/misspell/cmd/misspell
go get gopkg.in/alecthomas/gometalinter.v1/...

gometalinter.v1 --config="$GOPATH/src/.gometalinter.json" \
  $GOPATH/src/koding/... \
  $GOPATH/src/socialapi/...
