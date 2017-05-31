#!/bin/bash

# Koding post-provision script responsible for deploying a klient service.
#
# Copyright (C) 2012-2017 Koding Inc., all rights reserved.

set -euo pipefail

# The following variables are passed via terraform's variable block.
export KODING_USERNAME="$${KODING_USERNAME:-${var.koding_account_profile_nickname}}"
export KLIENT_URL="$${KLIENT_URL:-${var.koding_klient_url}}"
export SCREEN_URL="$${SCREEN_URL:-${var.koding_screen_url}}"

main() {
	echo "127.0.0.1 $${KODING_USERNAME}" >> /etc/hosts

	touch /var/log/klient.log \
	      /var/log/cloud-init-output.log

	mkdir -p /opt/kite/klient
	curl --location --silent --show-error --retry 5 "$${KLIENT_URL}" --output /tmp/klient.gz
	gzip --decompress --force --stdout /tmp/klient.gz > /opt/kite/klient/klient
	chmod +x /opt/kite/klient/klient

	chown -R "$${KODING_USERNAME}" \
		/opt/kite \
		/var/log/klient.log \
		/var/log/cloud-init-output.log

	/opt/kite/klient/klient -metadata-user "$${KODING_USERNAME}" -metadata-file /var/lib/koding/metadata.json run

	if [ -x /var/lib/koding/user-data.sh ]; then
		/var/lib/koding/user-data.sh
	fi
}

main &>>/var/log/cloud-init-output.log
