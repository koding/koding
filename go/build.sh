#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git

ldflags="-X koding/tools/lifecycle.version $(git rev-parse HEAD)"
services=(
	koding/broker
	koding/kites/os
	koding/kites/webterm
	koding/kites/irc
	koding/alice
)

go install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
cp bin/os bin/webterm bin/irc ../kites
rm -f ../kites/alice ../kites/broker ../kites/idshift ../kites/proxy ../kites/vmtool

mkdir -p build/broker
cp bin/broker build/broker/broker