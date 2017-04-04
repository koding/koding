#!/bin/bash

# Koding post-provision script responsible for deploying a klient service.
#
# Copyright (C) 2012-2017 Koding Inc., all rights reserved.

set -euo pipefail
trap "echo _KD_DONE_ | tee -a /var/log/cloud-init-output.log" EXIT

# The following variables are passed via terraform's variable block.
export KODING_USERNAME="$${KODING_USERNAME:-${var.koding_account_profile_nickname}}"
export KLIENT_URL="$${KLIENT_URL:-${var.koding_klient_url}}"
export SCREEN_URL="$${SCREEN_URL:-${var.koding_screen_url}}"

echo "127.0.0.1 $${KODING_USERNAME}" >> /etc/hosts

mkdir -p /opt/kite/klient

curl --location --silent --show-error --retry 5 "$${KLIENT_URL}" --output /tmp/klient.gz
curl --location --silent --show-error --retry 5 "$${SCREEN_URL}" --output /tmp/screen.tar.gz

touch /var/log/klient.log
tar -C / -xf /tmp/screen.tar.gz

# TODO(rjeczalik): Move the below to klient (altogether with installing screen).

if [ ! -x /usr/bin/screen ]; then
	ln -sf /opt/kite/klient/embedded/bin/screen /usr/bin/screen
fi

if [ ! -e /usr/share/terminfo ]; then
	mkdir -p /usr/share
	ln -sf /opt/kite/klient/embedded/share/terminfo /usr/share/terminfo
	ln -sf /usr/share/terminfo/X /usr/share/terminfo/x
fi

if [ ! -e /var/run/screen ]; then
	mkdir -p /var/run/screen
	chmod 0700 /var/run/screen
fi

gzip --decompress --force --stdout /tmp/klient.gz > /opt/kite/klient/klient
chmod +x /opt/kite/klient/klient
chown -R "$${KODING_USERNAME}:$${KODING_USERNAME}" /opt/kite/klient
chown "$${KODING_USERNAME}:$${KODING_USERNAME}" /var/log/klient.log /var/run/screen

/opt/kite/klient/klient -metadata-user "$${KODING_USERNAME}" -metadata-file /var/lib/koding/metadata.json run
