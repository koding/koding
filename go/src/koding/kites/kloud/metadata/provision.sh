#!/bin/bash

# Koding post-provision script responsible for deploying a klient service.
#
# Copyright (C) 2012-2017 Koding Inc., all rights reserved.

set -euo pipefail

# The following variables are passed via terraform's variable block.
export KODING_USERNAME="$${KODING_USERNAME:-${var.koding_account_profile_nickname}}"
export KLIENT_URL="$${KLIENT_URL:-${var.koding_klient_url}}"
export SCREEN_URL="$${SCREEN_URL:-${var.koding_screen_url}}"
export USE_EMBEDDED="$${USE_EMBEDDED:-${var.koding_use_embedded}}"

trap "echo _KD_DONE_ | tee -a /var/log/cloud-init-output.log" EXIT

install_screen() {
	curl --location --silent --show-error --retry 5 "$${SCREEN_URL}" --output /tmp/screen.tar.gz
    tar -C / -xf /tmp/screen.tar.gz

	groupadd --force screen
	usermod -a -G screen "$${KODING_USERNAME}"

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
		chown root:screen /var/run/screen
	fi
}

main() {
	echo "127.0.0.1 $${KODING_USERNAME}" >> /etc/hosts

	touch /var/log/klient.log \
	      /var/log/cloud-init-output.log

	if ! type screen &>/dev/null; then
		if [ $${USE_EMBEDDED} -eq 1 ]; then
			install_screen
		elif type yum &>/dev/null; then
			yum install --assumeyes screen
		elif type apt-get &>/dev/null; then
			apt-get install -y screen
		else
			install_screen
		fi
	fi

	mkdir -p /opt/kite/klient
	curl --location --silent --show-error --retry 5 "$${KLIENT_URL}" --output /tmp/klient.gz
	gzip --decompress --force --stdout /tmp/klient.gz > /opt/kite/klient/klient
	chmod +x /opt/kite/klient/klient

	chown -R "$${KODING_USERNAME}" \
		/opt/kite/klient \
		/var/log/klient.log \
		/var/log/cloud-init-output.log

	/opt/kite/klient/klient -metadata-user "$${KODING_USERNAME}" -metadata-file /var/lib/koding/metadata.json run

	if [ -x /var/lib/koding/user-data.sh ]; then
		/var/lib/koding/user-data.sh
	fi
}

main
