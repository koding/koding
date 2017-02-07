#!/bin/bash

set -euo pipefail

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GOBIN=${GOBIN:-${GOPATH}/bin}
export KODING_REPO=$(git rev-parse --show-toplevel)
export KODING_GIT_VERSION=$(git rev-parse HEAD || cat ./VERSION || cat ../VERSION || cat ../../../VERSION || echo "0")
export KODING_VERSION=${KODING_VERSION:-${KODING_GIT_VERSION:0:8}}
export KODING_LDFLAGS="-X koding/artifact.VERSION=${KODING_VERSION} -X main.GitCommit=${KODING_VERSION}"
export KODING_TAGS=""

koding-go-install() {
	go install -v -tags "${KODING_TAGS}" -ldflags "${KODING_LDFLAGS}" $*
}

export COMMANDS=(
	koding/kites/kontrol
	koding/kites/kloud
	koding/kites/kloud/kloudctl
	koding/kites/cmd/terraformer
	koding/kites/cmd/tunnelserver
	koding/workers/cmd/tunnelproxymanager
	koding/workers/removenonexistents
	koding/kites/kloud/cleaners/cmd/cleaner
	koding/kites/kloud/scripts/userdebug
	koding/kites/kloud/scripts/sl
	koding/klient
	koding/scripts/multiec2ssh

	socialapi/workers/api
	socialapi/workers/cmd/realtime
	socialapi/workers/cmd/realtime/gatekeeper
	socialapi/workers/cmd/realtime/dispatcher
	socialapi/workers/cmd/migrator
	socialapi/workers/cmd/algoliaconnector
	socialapi/workers/cmd/algoliaconnector/deletedaccountremover
	socialapi/workers/cmd/presence
	socialapi/workers/cmd/collaboration
	socialapi/workers/cmd/email/emailsender
	socialapi/workers/cmd/team
	socialapi/workers/algoliaconnector/tagmigrator
	socialapi/workers/algoliaconnector/contentmigrator

	vendor/github.com/koding/kite/kitectl
	vendor/github.com/canthefason/go-watcher
	vendor/github.com/mattes/migrate
	vendor/github.com/alecthomas/gocyclo
	vendor/github.com/remyoudompheng/go-misc/deadcode
	vendor/github.com/jteeuwen/go-bindata/go-bindata
	vendor/github.com/wadey/gocovmerge
	vendor/github.com/opennota/check/cmd/varcheck
)

export TERRAFORM_COMMANDS=(
	vendor/github.com/hashicorp/terraform
	$(go list vendor/github.com/hashicorp/terraform/builtin/bins/... | grep -v -E 'provisioner|provider-github')
)

export TERRAFORM_CUSTOM_COMMANDS=(
	koding/kites/cmd/provider-vagrant
	vendor/github.com/koding/terraform-provider-github/cmd/provider-github
	vendor/github.com/Banno/terraform-provider-marathon
)

# source configuration for kloud providers
for provider in $KODING_REPO/go/src/koding/kites/kloud/provider/*; do
	if [[ -d "${provider}/build.sh.d" ]]; then
		for src in ${provider}/build.sh.d/*; do
			if [[ -f "$src" ]]; then
				source "$src"
			fi
		done
	fi
done

fileToBeCleaned=$GOPATH/src/vendor/github.com/hashicorp/terraform/config/interpolate_funcs.go
grep "interpolationFuncFile()," $fileToBeCleaned && sed -i.bak '/interpolationFuncFile(),/d' $fileToBeCleaned

go generate koding/kites/config koding/kites/kloud/kloud

koding-go-install ${COMMANDS[@]} ${TERRAFORM_COMMANDS[@]}
koding-go-install ${TERRAFORM_CUSTOM_COMMANDS[@]}

# clean up unused resources in any case
rm -rf $GOBIN/terraform-provisioner-*

for cmd in $GOBIN/provider-*; do
	NAME=$(echo $cmd | rev | cut -d/ -f1 | rev)

	ln -sf $GOBIN/$NAME $GOBIN/terraform-$NAME
done
