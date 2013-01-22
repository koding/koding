#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)

ldflags="-X koding/tools/utils.version $(git rev-parse HEAD)"
services=(koding/broker koding/kites/os koding/kites/webterm koding/kites/irc koding/alice)

go install -v -ldflags "$ldflags" "${services[@]}"
cp $GOPATH/bin/* $GOPATH/../kites
