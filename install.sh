#!/usr/bin/env bash

if [[ ! "$(uname)" = "Linux" ]]; then
    echo "Currenty only Ubuntu Linux is supported"
    exit 1
fi

CHANNEL="development"

echo "Using ${CHANNEL} channel"

LATESTVERSION=$(curl -s https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest-version.txt)
LATESTURL="https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest/klient_0.1.${LATESTVERSION}_${CHANNEL}_amd64.deb"

echo "Downloading and installing klient 0.1.${LATESTVERSION}"
curl -s $LATESTURL -o klient.deb
sudo dpkg -i klient.deb > /dev/null

echo "Authenticate to Koding.com"
sudo -E /opt/kite/klient/klient -register -kite-home "/etc/kite"

if [ ! -f /etc/kite/kite.key ]; then
    echo "Kite.key not found. Aborting installation"
    exit -1
fi

# Production kontrol might return a different kontrol URL. Let us control this aspect.
KONTROLURL="https://koding.com/kontrol/kite"
escaped_var=$(printf '%s\n' "$KONTROLURL" | sed 's:[/&\]:\\&:g;s/$/\\/')
sudo sed -i "s/\.\/klient -kontrol-url $escaped_var \.\/klient/g/" "/etc/init/klient.conf"

# We need to restart it so it pick up the new environment variable
sudo service klient restart

