#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git

ldflags="-X koding/tools/lifecycle.version $(git rev-parse HEAD)"
services=(
	koding/broker
	koding/kites/os
	koding/kites/irc
	koding/virt/idshift
	koding/virt/proxy
	koding/virt/vmtool
	koding/alice
	koding/kontrol/daemon
	koding/kontrol/api
	koding/fujin
)

go install -v -ldflags "$ldflags" "${services[@]}"

rm -f $GOPATH/bin/ldapserver $GOPATH/../kites/ldapserver
cp $GOPATH/bin/* $GOPATH/../kites
