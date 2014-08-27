#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
if [ $# == 1 ]; then
  export GOBIN=$GOPATH/$1
fi

services=(
  koding/broker
  koding/rerouting
  koding/kites/os
  koding/kites/terminal
  github.com/koding/kite/kitectl
  github.com/koding/kite/reverseproxy/reverseproxy
  koding/kites/kontrol
  github.com/coreos/etcd
  koding/kites/klient
  koding/kites/kloud
  github.com/koding/kloudctl
  koding/virt/vmproxy
  koding/virt/vmtool
  koding/overview
  koding/kontrol/kontrolproxy
  koding/kontrol/kontrolftp
  koding/kontrol/kontroldaemon
  koding/kontrol/kontrolapi
  koding/kontrol/kontrolclient
  koding/workers/graphitefeeder
  koding/workers/guestcleanerworker
  socialapi/workers/api
  github.com/skelterjohn/rerun
)


`which go` install -v "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker
