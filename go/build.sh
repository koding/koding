#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git

ldflags="-X koding/tools/utils.version $(git rev-parse HEAD)"
services=(koding/broker koding/kites/irc koding/virt/idshift koding/virt/ldapserver koding/virt/proxy koding/alice)
if [ $(uname) == "Linux" ]; then
  services+=(koding/kites/os)
fi

go get -v -ldflags "$ldflags" "${services[@]}"
cp $GOPATH/bin/* $GOPATH/../kites
