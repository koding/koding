#!/usr/bin/env bash

set -euo pipefail

REPO_PATH=$(git rev-parse --show-toplevel)
CHANNEL=${1:-}
VERSION=${2:-}
KD_SEGMENTIO_KEY=${KD_SEGMENTIO_KEY}

export GOBIN="${REPO_PATH}"

die() {
	echo $* 1>&2
	exit 1
}

if [[ -z "$CHANNEL" ]]; then
	die "usage: build.sh CHANNEL [VERSION]"
fi

KONTROL_URL="https://koding.com/kontrol/kite"
if [[ "$CHANNEL" == "development" ]]; then
	KONTROL_URL="https://sandbox.koding.com/kontrol/kite"
fi

TUNNEL_URL="http://t.koding.com/kite"
if [[ "$CHANNEL" == "development" ]]; then
	TUNNEL_URL="http://dev-t.koding.com/kite"
fi

if [[ -z "$VERSION" ]]; then
	VERSION=$(curl -sSL https://koding-kd.s3.amazonaws.com/${CHANNEL}/latest-version.txt)
	let VERSION++
fi

kd_build() {
	go install -v -ldflags "-X koding/klientctl/config.Version=$VERSION -X koding/klientctl/config.SegmentKey=$KD_SEGMENTIO_KEY -X koding/klientctl/config.Environment=$CHANNEL" koding/klientctl
	mv "${REPO_PATH}/klientctl" "${REPO_PATH}/kd"
}

PREFIX="kd-0.1.${VERSION}"

echo "# builing kd: version ${VERSION}, channel ${CHANNEL}, os $(uname)"

if [[ "$(uname)" == "Linux" ]]; then
	if [[ -z "$VERSION" ]]; then
		die "usage: build.sh CHANNEL [VERSION]"
	fi

	pushd $REPO_PATH

	kd_build

	gzip -9 -N -f kd
	mv kd.gz "${PREFIX}.linux_amd64.gz"

	popd

	exit 0
fi

pushd $REPO_PATH

kd_build

if [[ -z "${KD_DEBUG:-}" ]]; then
	gzip -9 -N -f kd
	mv kd.gz "${PREFIX}.darwin_amd64.gz"

	docker run -t -v $PWD:/opt/koding -e KD_SEGMENTIO_KEY="$KD_SEGMENTIO_KEY" koding/base:klient go/src/koding/klientctl/build.sh "$CHANNEL" "$VERSION"
fi

popd

echo "# built kd successfully: version ${VERSION}, channel ${CHANNEL}, os $(uname)"
