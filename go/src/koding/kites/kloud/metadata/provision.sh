#!/bin/bash

# Koding post-provision script responsible for deploying a klient service.
#
# Copyright (C) 2012-2017 Koding Inc., all rights reserved.

set -euo pipefail
trap "echo _KD_DONE_ | tee -a /var/log/cloud-init-output.log" EXIT

echo "127.0.0.1 {{.Hostname}}" >> /etc/hosts

mkdir -p /opt/kite/klient

wget "{{.KlientURL}}" --retry-connrefused --tries 5 -O /tmp/klient.gz
wget "{{.ScreenURL}}" --retry-connrefused --tries 5 -O /tmp/screen.tar.gz

tar -C / -xf /tmp/screen.tar.gz

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
	chmod 0755 /var/run/screen
fi

gzip --decompress --force --stdout /tmp/klient.gz > /opt/kite/klient/klient
chmod +x /opt/kite/klient/klient
chown -R "{{.Username}}:{{.Username}}" /opt/kite/klient

/opt/kite/klient/klient -metadata-user "{{.Username}}" -metadata-file /var/lib/koding/metadata.json run

if [[ -x /var/lib/koding/user-data.sh ]]; then
	/var/lib/koding/user-data.sh
fi
