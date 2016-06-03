#!/bin/bash

set -euo pipefail

REPO_PATH=$(git rev-parse --show-toplevel)

# configure s3cmd
cat >$HOME/.s3cfg <<EOF
[default]
access_key=$S3_KEY_ID
secret_key=$S3_KEY_SECRET
EOF

if [[ -z "$KLIENT_CHANNEL" ]]; then
	KLIENT_CHANNEL=${CHANNEL:-}
fi

export S3DIR="s3://koding-klient/$KLIENT_CHANNEL"

# fetch the latest build number since wercker doesn't provide one
s3cmd get $S3DIR/latest-version.txt version

export OLDBUILDNO=$(cat version)
export NEWBUILDNO=$(($OLDBUILDNO + 1))
export KLIENT_PREFIX="klient-0.1.$NEWBUILDNO"
export KLIENT_DEB="klient_0.1.${NEWBUILDNO}_${KLIENT_CHANNEL}_amd64.deb"

echo "New version will be: $NEWBUILDNO"
rm -f version

klient_build() {
	GOOS="${1:-}" GOARCH=amd64 go build -v -ldflags "-X koding/klient/protocol.Version 0.1.$NEWBUILDNO -X koding/klient/protocol.Environment $KLIENT_CHANNEL" -o klient koding/klient
}

# build klient binary for linux
klient_build

# validate klient version
[[ $(./klient -version) == "0.1.$NEWBUILDNO" ]]

# prepare klient.gz
gzip -9 -N -f klient
mv klient.gz ${KLIENT_PREFIX}.gz

# prepare klient.deb
go run "${REPO_PATH}/go/src/koding/klient/build/build.go" -e $KLIENT_CHANNEL -b $NEWBUILDNO
dpkg -f $KLIENT_DEB

klient_build "darwin"
gzip -9 -N -f klient
mv klient.gz ${KLIENT_PREFIX}.darwin_amd64.gz

#  Copy files to S3.
s3cmd -P put $KLIENT_DEB ${KLIENT_PREFIX}* $S3DIR/$NEWBUILDNO/

# Keep a copy of klient under /latest/ without version number in the name,
# so it can be downloaded without prior lookup of latest version number.
cp -f klient{-0.1.$NEWBUILDNO,}.gz
cp -f klient{-0.1.$NEWBUILDNO,}.darwin_amd64.gz
cp -f $KLIENT_DEB klient.deb

# Cleanup the latest/ folder and put the latest one in there
s3cmd del --recursive $S3DIR/latest/
s3cmd -P put klient.deb klient.gz klient.darwin_amd64.gz $S3DIR/latest/

# Update latest-version.txt with the latest version
s3cmd del $S3DIR/latest-version.txt
echo $NEWBUILDNO >latest-version.txt
s3cmd -P put latest-version.txt $S3DIR/latest-version.txt

#  Update install.sh file
s3cmd del s3://koding-klient/install.sh
s3cmd -P put "${REPO_PATH}/go/src/koding/klient/install.sh" s3://koding-klient/install.sh
