#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git

ldflags="-X koding/tools/lifecycle.version $(git rev-parse HEAD)"
services=(koding/broker koding/kites/os koding/kites/irc koding/virt/idshift koding/virt/ldapserver koding/virt/proxy koding/alice)

go install -v -ldflags "$ldflags" "${services[@]}"
cp $GOPATH/bin/* $GOPATH/../kites
