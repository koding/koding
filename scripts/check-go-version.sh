#!/bin/bash

VERSION=$(go version 2>/dev/null)
VERSION=${VERSION:13:4}
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f2)

if [[ $MAJOR -lt 1 ]]; then
	MISMATCH=1
elif [[ $MAJOR -eq 1 && $MINOR -lt 1 ]]; then
	MISMATCH=1
fi

if [[ -n $MISMATCH ]]; then
	echo 'error: go version must be 1.8.x'
	echo ''
	echo 'for mac you might use to upgrade: '
	echo '	export GO_VERSION="1.8"'
	echo '	export GO_TARBALL="go$GO_VERSION.darwin-amd64.tar.gz"'
	echo '	export GO_SRC_URL="https://storage.googleapis.com/golang/$GO_TARBALL"'
	echo '	curl --silent $GO_SRC_URL | tar --extract --gzip --directory=/usr/local'
	exit 1
fi
