#!/bin/bash

set -euo pipefail

REPO_PATH=$(git rev-parse --show-toplevel)
CHANNEL=${1:-}
VERSION=${2:-}

export GOBIN="${REPO_PATH}"

die() {
	echo $* 1>&2
	exit 1
}

if [[ -z "$CHANNEL" ]]; then
	die "usage: build.sh CHANNEL [VERSION]"
fi

if [[ -z "$VERSION" ]]; then
	VERSION=$(curl -sSL https://koding-klient.s3.amazonaws.com/${CHANNEL}/latest-version.txt)
	let VERSION++
fi

PREFIX="klient-0.1.${VERSION}"

klient_build() {
	go install -v -ldflags "-X koding/klient/config.Version=0.1.${VERSION} -X koding/klient/config.Environment=${CHANNEL}" koding/klient
}

echo "# builing klient: version ${VERSION}, channel ${CHANNEL}, os $(uname)"

if [[ "$(uname)" == "Linux" ]]; then
	if [[ -z "$VERSION" ]]; then
		die "usage: build.sh CHANNEL [VERSION]"
	fi

	PREFIX_DEB="klient_0.1.${VERSION}_${CHANNEL}_amd64.deb"

	pushd $REPO_PATH

	klient_build

	# validate klient version
	[[ $(./klient -version) == "0.1.${VERSION}" ]]

	# prepare klient.gz
	gzip -9 -N -f klient
	mv klient.gz "${PREFIX}.gz"

	echo "# running: go run ${REPO_PATH}/go/src/koding/klient/build/build.go -e ${CHANNEL} -b ${VERSION}"
	go run "${REPO_PATH}/go/src/koding/klient/build/build.go" -e "$CHANNEL" -b "$VERSION"
	dpkg -f "$PREFIX_DEB"

	popd

	exit 0
fi

pushd $REPO_PATH

klient_build

if [[ -z "${KD_DEBUG:-}" ]]; then
	gzip -9 -N -f klient
	mv klient.gz "${PREFIX}.darwin_amd64.gz"

	docker run -t -v $PWD:/opt/koding koding/base:klient go/src/koding/klient/build.sh "$CHANNEL" "$VERSION"
fi

popd

echo "# built klient successfully: version ${VERSION}, channel ${CHANNEL}, os $(uname)"
