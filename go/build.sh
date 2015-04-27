#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git
if [ $# == 1 ]; then
  export GOBIN=$GOPATH/$1
fi

# first try to fetch it from git HEAD
# then try to read currrent directory
# it may be in one upper folder - if you are in go folder
# it may be in root folder if you are in socialapi folder
version=$(git rev-parse HEAD || cat ./VERSION || cat ../VERSION || cat ../../../VERSION || echo "0")
ldflags="-X koding/artifact.VERSION ${version:0:8}"

services=(
  koding/broker
  koding/rerouting
  koding/kites/os
  koding/kites/terminal
  github.com/koding/kite/kitectl
  koding/kites/kontrol
  github.com/coreos/etcd
  koding/kites/kloud
  koding/kites/cmd/terraformer
  koding/kites/kloud/kloudctl
  koding/kites/cmd/terraformer
  koding/virt/vmproxy
  koding/virt/vmtool
  koding/overview
  koding/kontrol/kontrolproxy
  koding/kontrol/kontrolftp
  koding/kontrol/kontroldaemon
  koding/kontrol/kontrolapi
  koding/kontrol/kontrolclient
  koding/workers/guestcleanerworker
  github.com/canthefason/go-watcher
  github.com/mattes/migrate
  koding/go-webserver
  koding/vmwatcher

  socialapi/workers/api
  socialapi/workers/cmd/notification
  socialapi/workers/cmd/pinnedpost
  socialapi/workers/cmd/popularpost
  socialapi/workers/cmd/trollmode
  socialapi/workers/cmd/populartopic
  socialapi/workers/cmd/realtime
  socialapi/workers/cmd/realtime/gatekeeper
  socialapi/workers/cmd/realtime/dispatcher
  socialapi/workers/cmd/topicfeed
  socialapi/workers/cmd/migrator
  socialapi/workers/cmd/sitemap/sitemapfeeder
  socialapi/workers/cmd/sitemap/sitemapgenerator
  socialapi/workers/cmd/sitemap/sitemapinitializer
  socialapi/workers/cmd/algoliaconnector
  socialapi/workers/payment/paymentwebhook
  socialapi/workers/cmd/topicmoderation
  socialapi/workers/cmd/collaboration
  socialapi/workers/cmd/email/activityemail
  socialapi/workers/cmd/email/dailyemail
  socialapi/workers/cmd/email/privatemessageemailfeeder
  socialapi/workers/cmd/email/privatemessageemailsender
  socialapi/workers/cmd/email/emailsender
  socialapi/workers/cmd/team
  socialapi/workers/cmd/integration/webhook
  socialapi/workers/algoliaconnector/tagmigrator
  socialapi/workers/algoliaconnector/contentmigrator
)


`which go` install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker


#
# terraform related build operations
# TODO ~ this should be done in a more elegant way
#
# tldflags="-X main.GitCommit ${version:0:8}"

# `which go` build -o bin/terraform-provider-aws -v -ldflags "$tldflags" github.com/hashicorp/terraform/builtin/bins/provider-aws
# `which go` build -o bin/terraform-provider-terraform -v -ldflags "$tldflags" github.com/hashicorp/terraform/builtin/bins/provider-terraform

# `which go` build -o bin/terraform-provisioner-file -v -ldflags "$tldflags" github.com/hashicorp/terraform/builtin/bins/provisioner-file
# `which go` build -o bin/terraform-provisioner-local-exec -v -ldflags "$tldflags" github.com/hashicorp/terraform/builtin/bins/provisioner-local-exec
# `which go` build -o bin/terraform-provisioner-remote-exec -v -ldflags "$tldflags" github.com/hashicorp/terraform/builtin/bins/provisioner-remote-exec

