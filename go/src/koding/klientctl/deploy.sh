#!/usr/bin/env bash

set -euo pipefail

REPO_PATH=$(git rev-parse --show-toplevel)
CHANNEL=${1:-}
VERSION=${2:-}
PROFILE=${3:-koding-klient}
BUCKET=${4:-koding-kd}

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

pushd "${REPO_PATH}"

[[ -f "kd-0.1.${VERSION}.linux_amd64.gz" ]]
[[ -f "kd-0.1.${VERSION}.darwin_amd64.gz" ]]

echo "# uploading files to s3://${BUCKET}/${CHANNEL}/"

s3cp "kd-0.1.${VERSION}.linux_amd64.gz" "s3://${BUCKET}/${CHANNEL}/"
s3cp "kd-0.1.${VERSION}.darwin_amd64.gz" "s3://${BUCKET}/${CHANNEL}/"

s3rm "s3://${BUCKET}/${CHANNEL}/kd.linux_amd64.gz" || true
s3cp "s3://${BUCKET}/${CHANNEL}/kd-0.1.${VERSION}.linux_amd64.gz" "s3://${BUCKET}/${CHANNEL}/kd.linux_amd64.gz"

s3rm "s3://${BUCKET}/${CHANNEL}/kd.darwin_amd64.gz" || true
s3cp "s3://${BUCKET}/${CHANNEL}/kd-0.1.${VERSION}.darwin_amd64.gz" "s3://${BUCKET}/${CHANNEL}/kd.darwin_amd64.gz"

cp -f go/src/koding/klientctl/install-kd.sh install-kd.sh
sed -i"" -e "s|\%RELEASE_CHANNEL\%|${CHANNEL}|g" install-kd.sh
s3rm "s3://${BUCKET}/${CHANNEL}/install-kd.sh"
s3cp install-kd.sh "s3://${BUCKET}/${CHANNEL}/install-kd.sh"
rm -f install-kd.sh

echo "# updating latest-version.txt to $VERSION"

echo $VERSION > latest-version.txt

s3rm "s3://${BUCKET}/${CHANNEL}/latest-version.txt"
s3cp latest-version.txt "s3://${BUCKET}/${CHANNEL}/latest-version.txt"

rm -f latest-version.txt

popd
