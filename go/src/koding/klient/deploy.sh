#!/usr/bin/env bash

set -euo pipefail

REPO_PATH=$(git rev-parse --show-toplevel)
CHANNEL=${1:-}
VERSION=${2:-}
PROFILE=${3:-koding-klient}
BUCKET=${4:-koding-klient}

die() {
	echo $* 1>&2
	exit 1
}

if [[ -z "$CHANNEL" ]] || [[ -z "$VERSION" ]]; then
	die "usage: deploy.sh CHANNEL VERSION [AWS PROFILE] [S3 BUCKET]"
fi

s3cp() {
	aws --profile "$PROFILE" s3 cp --acl public-read $*
}

s3rm() {
	aws --profile "$PROFILE" s3 rm $*
}

DISTRIB=(
	"${REPO_PATH}/klient-0.1.${VERSION}.gz"
	"${REPO_PATH}/klient-0.1.${VERSION}.darwin_amd64.gz"
	"${REPO_PATH}/klient_0.1.${VERSION}_${CHANNEL}_amd64.deb"
)


for file in "${DISTRIB[@]}"; do
	[[ -f "$file" ]]
done

echo "# uploading files to s3://${BUCKET}/${CHANNEL}/${VERSION}/"

for file in "${DISTRIB[@]}"; do
	s3cp "$file" "s3://${BUCKET}/${CHANNEL}/${VERSION}/"
done

echo "# uploading files to s3://${BUCKET}/${CHANNEL}/latest/"

s3rm --recursive "s3://${BUCKET}/${CHANNEL}/latest/"

s3cp "s3://${BUCKET}/${CHANNEL}/${VERSION}/klient-0.1.${VERSION}.gz" "s3://${BUCKET}/${CHANNEL}/latest/"
s3cp "s3://${BUCKET}/${CHANNEL}/${VERSION}/klient-0.1.${VERSION}.darwin_amd64.gz" "s3://${BUCKET}/${CHANNEL}/latest/"
s3cp "s3://${BUCKET}/${CHANNEL}/${VERSION}/klient_0.1.${VERSION}_${CHANNEL}_amd64.deb" "s3://${BUCKET}/${CHANNEL}/latest/"

s3cp "s3://${BUCKET}/${CHANNEL}/latest/klient-0.1.${VERSION}.gz" "s3://${BUCKET}/${CHANNEL}/latest/klient.gz"
s3cp "s3://${BUCKET}/${CHANNEL}/latest/klient-0.1.${VERSION}.darwin_amd64.gz" "s3://${BUCKET}/${CHANNEL}/latest/klient.darwin_amd64.gz"
s3cp "s3://${BUCKET}/${CHANNEL}/latest/klient_0.1.${VERSION}_${CHANNEL}_amd64.deb" "s3://${BUCKET}/${CHANNEL}/latest/klient.deb"

echo "# updating latest-version.txt to $VERSION"

echo $VERSION > latest-version.txt

s3rm "s3://${BUCKET}/${CHANNEL}/latest-version.txt"
s3cp latest-version.txt "s3://${BUCKET}/${CHANNEL}/latest-version.txt"

rm -f latest-version.txt
