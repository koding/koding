#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git
if [ $# == 1 ]; then
  export GOBIN=$GOPATH/$1
fi

version=$(git rev-parse HEAD || cat ../VERSION || echo "0")
ldflags="-X koding/artifact.VERSION ${version:0:8}"

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
  koding/kites/kloud/kloudctl
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
  github.com/skelterjohn/rerun
  koding/go-webserver

  socialapi/workers/api
  socialapi/workers/emailnotifier
  socialapi/workers/dailyemailnotifier
  socialapi/workers/notification
  socialapi/workers/pinnedpost
  socialapi/workers/popularpost
  socialapi/workers/trollmode
  socialapi/workers/populartopic
  socialapi/workers/realtime
  socialapi/workers/topicfeed
  socialapi/workers/migrator
  socialapi/workers/sitemap/sitemapfeeder
  socialapi/workers/sitemap/sitemapgenerator
  socialapi/workers/sitemap/sitemapinitializer
  socialapi/workers/algoliaconnector
)


`which go` install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker
