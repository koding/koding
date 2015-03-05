#!/usr/bin/env bash

CHANNEL="development"

echo "Using ${CHANNEL} channel"

LATESTVERSION=$(curl -s https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest-version.txt)
LATESTURL="https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest/klient_0.1.${LATESTVERSION}_${CHANNEL}_amd64.deb"

echo "Downloading and installing klient 0.1.${LATESTVERSION}"
curl -s $LATESTURL -o klient.deb
sudo dpkg -i klient.deb > /dev/null

echo "Authenticate to Koding.com"
/opt/kite/klient/klient -register
