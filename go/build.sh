#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)
/usr/local/go/bin/go get -v koding/kites/webterm koding/kites/os
cp $GOPATH/bin/* $GOPATH/../kites
