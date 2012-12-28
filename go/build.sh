#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)

ldflags="-X koding/tools/utils.version $(git rev-parse HEAD)"
services=(koding/broker koding/kites/irc koding/alice)
if [ $(uname) == "Linux" ]; then
  services+=(koding/kites/os)
fi

/usr/local/go/bin/go get -v -ldflags "$ldflags" $services
cp $GOPATH/bin/* $GOPATH/../kites
