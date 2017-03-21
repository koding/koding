#!/bin/bash

set -o errexit

export GOPATH=${GOPATH:-$(pwd)/go} \
       GOBIN=${GOBIN:-$GOPATH/bin}

go get github.com/gordonklaus/ineffassign
go get github.com/client9/misspell/cmd/misspell
go get gopkg.in/alecthomas/gometalinter.v1/...

$GOBIN/gometalinter.v1 --config="$GOPATH/src/.gometalinter.json" \
  $GOPATH/src/koding/... \
  $GOPATH/src/socialapi/...
