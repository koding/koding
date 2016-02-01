#!/bin/bash

set -euo pipefail

# configure s3cmd
echo '[default]' > ~/.s3cfg
echo "access_key=$S3_ACCESS_KEY" >> ~/.s3cfg
echo "secret_key=$S3_SECRET_KEY" >> ~/.s3cfg

export S3DIR="s3://koding-klient/$KLIENT_CHANNEL"

# fetch the latest build number since wercker doesn't provide one
s3cmd get $S3DIR/latest-version.txt version

export OLDBUILDNO=$(cat version)
export NEWBUILDNO=$(($OLDBUILDNO+1))

echo "New version will be: $NEWBUILDNO"
rm -f version

# build klient binary
go build -v -ldflags "-X koding/klient/protocol.Version 0.1.$NEWBUILDNO -X koding/klient/protocol.Environment $KLIENT_CHANNEL" koding/klient

# validate klient version
[[ $(./klient -version) == "0.1.$NEWBUILDNO" ]]

# prepare klient.gz
gzip -N klient
mv klient.gz klient-0.1.$NEWBUILDNO.gz

# prepare klient.deb
go run build/build.go -e $KLIENT_CHANNEL -b $NEWBUILDNO
dpkg -f *.deb

# upload gz and deb to s3
  
#  Copy files to S3.
s3cmd -P put *.deb  $S3DIR/$NEWBUILDNO/
s3cmd -P put *.gz  $S3DIR/$NEWBUILDNO/

# Cleanup the latest/ folder and put the latest one in there
s3cmd del --recursive $S3DIR/latest/
s3cmd -P put *.deb  $S3DIR/latest/
s3cmd -P put *.gz  $S3DIR/latest/

# Update latest-version.txt with the latest version
s3cmd del $S3DIR/latest-version.txt
echo $NEWBUILDNO > latest-version.txt
s3cmd -P put latest-version.txt $S3DIR/latest-version.txt

#  Update install.sh file
s3cmd del s3://koding-klient/install.sh
s3cmd -P put install.sh s3://koding-klient/install.sh

