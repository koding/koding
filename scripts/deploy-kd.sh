#!/bin/bash

set -euo pipefail

REPO_PATH=$(git rev-parse --show-toplevel)

# configure s3cmd
cat >$HOME/.s3cfg <<EOF
[default]
access_key=$S3_KEY_ID
secret_key=$S3_KEY_SECRET
EOF

export S3DIR="s3://koding-kd/$CHANNEL"

# fetch the latest build number since wercker doesn't provide one
s3cmd get $S3DIR/latest-version.txt version

export OLDBUILDNO=$(cat version)
export NEWBUILDNO=$(($OLDBUILDNO + 1))
export KD_SEGMENTIO_KEY=${KD_SEGMENTIO_KEY:-} # BUG(lee): remove when segmentio is configured

echo "New version will be: $NEWBUILDNO"
rm -f version

KONTROL_URL="https://koding.com/kontrol/kite"
if [[ "$CHANNEL" == "development" ]]; then
	KONTROL_URL="https://sandbox.koding.com/kontrol/kite"
fi

TUNNEL_URL="http://t.koding.com/kite"
if [[ "$CHANNEL" == "development" ]]; then
	TUNNEL_URL="http://dev-t.koding.com/kite"
fi

# NOTE(rjeczalik): kd expects the version to be a single digit, while klient
# expect semver - making a note until this is made consistent.
kd_build() {
	GOOS="${1:-}" GOARCH=amd64 go build -v -ldflags "-X koding/klientctl/config.Version $NEWBUILDNO -X koding/klientctl/config.SegmentKey \"$KD_SEGMENTIO_KEY\" -X koding/klientctl/config.Environment $CHANNEL -X koding/klientctl/config.TunnelKiteAddress $TUNNEL_URL -X koding/klientctl/config.KontrolURL $KONTROL_URL" -o kd koding/klientctl
}

# build klient binary for linux
kd_build

# validate klient version
[[ "$(./kd -version)" == "kd version 0.1.${NEWBUILDNO}" ]]

# prepare klient.gz
gzip -9 -N -f kd
mv kd.gz kd-0.1.$NEWBUILDNO.linux_amd64.gz

kd_build darwin
gzip -9 -N -f kd
mv kd.gz kd-0.1.$NEWBUILDNO.darwin_amd64.gz

#  Copy files to S3.
s3cmd -P put kd-0.1.$NEWBUILDNO.*.gz $S3DIR/

# Update latest-version.txt with the latest version
s3cmd del $S3DIR/latest-version.txt
echo $NEWBUILDNO >latest-version.txt
s3cmd -P put latest-version.txt $S3DIR/latest-version.txt

#  Update install-kd.sh file
cp -f "${REPO_PATH}/go/src/koding/klientctl/install-kd.sh" install-kd.sh
sed -i -e "s|\%RELEASE_CHANNEL\%|${CHANNEL}|g" install-kd.sh
s3cmd del $S3DIR/install-kd.sh
s3cmd -P put install-kd.sh $S3DIR/install-kd.sh
