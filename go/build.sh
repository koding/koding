#!/bin/bash

set -euo pipefail

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GOBIN=${GOBIN:-${GOPATH}/bin}
export KODING_REPO=$(git rev-parse --show-toplevel || $(cd $(dirname "$0")/..; pwd))
export KODING_GIT_VERSION=$(git rev-parse --short HEAD || cat ./VERSION || cat ../VERSION || cat ../../../VERSION || echo "0")
export KODING_VERSION=${KODING_VERSION:-$KODING_GIT_VERSION}
export KODING_LDFLAGS="-X koding/artifact.VERSION=${KODING_VERSION} -X main.GitCommit=${KODING_VERSION} -s"
export KODING_TAGS=""
export KONFIG_ENVIRONMENT=${KONFIG_ENVIRONMENT:-default}

koding-go-install() {
	go install -v -tags "${KODING_TAGS}" -ldflags "${KODING_LDFLAGS}" $*
}

klient-go-install() {
	local destination_dir=${KONFIG_PROJECTROOT:-$KODING_REPO}/website/a/klient/$KONFIG_ENVIRONMENT
	mkdir -p $destination_dir
	local version_file=$destination_dir/latest-version.txt
	[[ -f $version_file ]] || echo -1 > $version_file
	local version=$(($(cat $version_file) + 1))
	go install -v -ldflags "-X koding/klient/config.Version=0.1.$version -X koding/klient/config.Environment=$KONFIG_ENVIRONMENT" koding/klient
	IFS='.', read major minor version < <($GOBIN/klient --version)
	echo $version > $version_file
}

export COMMANDS=(
	koding/kites/kontrol
	koding/kites/kloud
	koding/kites/kloud/kloudctl
	koding/kites/cmd/terraformer
	koding/kites/cmd/tunnelserver
	koding/workers/cmd/tunnelproxymanager
	koding/workers/removenonexistents
	koding/kites/kloud/scripts/userdebug
	koding/kites/kloud/scripts/sl
	koding/klientctl
	koding/scripts/multiec2ssh
	socialapi/workers/api
	socialapi/workers/cmd/realtime
	socialapi/workers/cmd/realtime/gatekeeper
	socialapi/workers/cmd/realtime/dispatcher
	socialapi/workers/cmd/migrator
	socialapi/workers/cmd/presence
	socialapi/workers/cmd/collaboration
	socialapi/workers/cmd/email/emailsender
	socialapi/workers/cmd/team
	vendor/github.com/koding/kite/kitectl
	vendor/github.com/canthefason/go-watcher
	vendor/github.com/mattes/migrate
	vendor/github.com/alecthomas/gocyclo
	vendor/github.com/remyoudompheng/go-misc/deadcode
	vendor/github.com/jteeuwen/go-bindata/go-bindata
	vendor/github.com/wadey/gocovmerge
	vendor/github.com/opennota/check/cmd/varcheck
	vendor/gopkg.in/alecthomas/gometalinter.v1
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
klient-go-install

# clean up unused resources in any case
rm -rf $GOBIN/terraform-provisioner-*

for cmd in $GOBIN/provider-*; do
	NAME=$(echo $cmd | rev | cut -d/ -f1 | rev)

	ln -sf $GOBIN/$NAME $GOBIN/terraform-$NAME
done
