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
  koding/persistence
  github.com/koding/kite/cmd/kite
  github.com/koding/kite/reverseproxy/reverseproxy
  koding/kites/kontrol
  koding/virt/vmproxy
  koding/virt/vmtool
  koding/overview
  koding/kontrol/kontrolproxy
  koding/kontrol/kontrolftp
  koding/kontrol/kontroldaemon
  koding/kontrol/kontrolapi
  koding/kontrol/kontrolclient
  koding/workers/elasticsearchfeeder
  koding/workers/externals
  koding/workers/graphitefeeder
  koding/cron
  socialapi/workers/api
)

go install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker
