#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git
if [ $# == 1 ]; then
  export GOBIN=$GOPATH/$1
fi

# ver contains the last digit of a go version, i.e: for v1.5 it contains 5, for
# devel version it's empty; we are using it because the link operator has
# changed after v1.5, previously it was an empty space, now its '='
# (following code is retrieved from: https://github.com/coreos/etcd/blob/master/build)
val=$(go version)
ver=$(echo $val | awk -F ' ' '{print $3}' | awk -F '.' '{print $2}')
if [[ -z "$ver" ]] || [[ $ver -gt 4 ]]; then
	LINK_OPERATOR="="
else
	LINK_OPERATOR=" "
fi

# first try to fetch it from git HEAD
# then try to read currrent directory
# it may be in one upper folder - if you are in go folder
# it may be in root folder if you are in socialapi folder
version=$(git rev-parse HEAD || cat ./VERSION || cat ../VERSION || cat ../../../VERSION || echo "0")
ldflags="-X koding/artifact.VERSION${LINK_OPERATOR}${version:0:8}"

services=(
  koding/broker
  koding/rerouting
  koding/kites/kontrol
  koding/kites/kloud
  koding/kites/kloud/kloudctl
  koding/kites/cmd/terraformer
  koding/kites/cmd/tunnelserver
  koding/workers/guestcleanerworker
  koding/go-webserver
  koding/workers/cmd/tunnelproxymanager
  koding/vmwatcher
  koding/workers/janitor
  koding/workers/gatheringestor
  koding/workers/appstoragemigrator
  koding/kites/kloud/cleaners/cmd/cleaner
  koding/kites/kloud/scripts/userdebug
  koding/kites/kloud/scripts/sl
  koding/klient

  github.com/koding/kite/kitectl
  github.com/canthefason/go-watcher
  github.com/mattes/migrate

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
  socialapi/workers/cmd/algoliaconnector/deletedaccountremover
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
  socialapi/workers/cmd/integration/eventsender
  socialapi/workers/cmd/integration/webhookmiddleware

  github.com/alecthomas/gocyclo
  github.com/remyoudompheng/go-misc/deadcode
  github.com/opennota/check/cmd/varcheck
  github.com/jteeuwen/go-bindata/go-bindata
)


`which go` install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker

# build terraform services
terraformservices=(
  github.com/hashicorp/terraform/builtin/bins/provider-aws
  github.com/hashicorp/terraform/builtin/bins/provider-terraform
  github.com/hashicorp/terraform/builtin/bins/provider-null
  github.com/koding/terraform-provider-github/cmd/provider-github
  koding/kites/cmd/provider-vagrant

  github.com/hashicorp/terraform/builtin/bins/provisioner-file
  github.com/hashicorp/terraform/builtin/bins/provisioner-local-exec
  github.com/hashicorp/terraform/builtin/bins/provisioner-remote-exec

)

tldflags="-X main.GitCommit${LINK_OPERATOR}${version:0:8}"
`which go` install -v -ldflags "$tldflags"  "${terraformservices[@]}"

for i in "${terraformservices[@]}"
do
  # split each entry from `/` to an array of strings from a string
  IFS='/ ' read -a paths <<< "$i"

  # if GOBIN is not set, generate it from GOPATH
  if [[ -z "$GOBIN" ]]; then
    GOBIN=$GOPATH/bin
  fi

  FILE=${paths[${#paths[@]}-1]} # only use the last folder name

  # rename files with terraform prefix
  # cp instead of mv because build tool will always try to build again and again
  cp $GOBIN/$FILE $GOBIN/terraform-$FILE
done
