#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)
/usr/local/go/bin/go get -v koding/broker koding/kites/webterm koding/kites/os koding/kites/irc
cp $GOPATH/bin/* $GOPATH/../kites
