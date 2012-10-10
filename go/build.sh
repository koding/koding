#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)

/usr/local/go/bin/go get -v koding/broker koding/kites/webterm koding/kites/irc

if [ $(uname) == "Linux" ]; then
  /usr/local/go/bin/go get -v koding/kites/os
fi

cp $GOPATH/bin/* $GOPATH/../kites
