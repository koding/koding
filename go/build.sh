#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git
if [ $# == 1 ]; then
  export GOBIN=$GOPATH/$1
fi

ldflags="-X koding/tools/lifecycle.version $(git rev-parse HEAD)"
services=(
  koding/broker
  koding/rerouting
  koding/userpresence
  koding/persistence
  koding/kites/os
  koding/kites/irc
  koding/virt/vmproxy
  koding/virt/vmtool
  koding/alice
  koding/kontrol/kontrolproxy
  koding/kontrol/kontrolftp
  koding/kontrol/kontroldaemon
  koding/kontrol/kontrolapi
  koding/kontrol/kontrolclient
  koding/workers/neo4jfeeder
  koding/dns
)

go install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker
