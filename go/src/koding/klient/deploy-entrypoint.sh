#!/bin/bash

set -euo pipefail

# Koding entrypoint.
#
# This script generates N entrypoint files and uploads them to S3.
# This is a workaround for Mesos which does not escape a value
# for -entrypoint flag, which makes it impossible to pass
# arguments to an entrypoint script.
#
# Entrypoint script needs to know the application number
# for which it is being executed - in order to read Koding
# metadata.
#
# Since passing arguments is not an option (or I failed to
# make it working) we instead read the metadata number
# from the entrypoint file name. Hacks ¯\_(ツ)_/¯.

N=${1:-20}
KODING_PROFILE=${KODING_PROFILE:-koding-klient}

s3cp() {
	aws --profile "$KODING_PROFILE" s3 cp --acl public-read $*
}

s3rm() {
	aws --profile "$KODING_PROFILE" s3 rm $*
}

pushd $(mktemp -d /tmp/XXXXXX)

mkdir entrypoint

for i in $(seq 1 $N); do

	cat >entrypoint/entrypoint.${i}.sh <<EOF
#!/bin/sh

set -eu

# Koding Entrypoint.
#
# This script is a part of Koding. It wraps container's entrypoint
# and injects a Klient service into it in order to connect
# that container with Koding.
#
# Container must no use it's own custom entrypoint
# in order to have this wrapper script work.
#
# Maintenance: Rafal Jeczalik <rafal@koding.com>

export USER_LOG=/var/log/cloud-init-output.log
export KODING_CMD=\${KODING_CMD:-}
trap "echo _KD_DONE_ | tee -a \$USER_LOG" EXIT

echo "[entrypoint] connecting to Koding wih KODING_METADATA_${i}" | tee -a \$USER_LOG >&2

tar -C / -xf /mnt/mesos/sandbox/screen.tar.gz

if [ ! -x /usr/bin/screen ]; then
	ln -sf /opt/kite/klient/embedded/bin/screen /usr/bin/screen
fi

if [ ! -e /usr/share/terminfo ]; then
	mkdir -p /usr/share
	ln -sf /opt/kite/klient/embedded/share/terminfo /usr/share/terminfo
	ln -sf /usr/share/terminfo/X /usr/share/terminfo/x
fi

if [ ! -e /var/run/screen ]; then
	mkdir -p /tmp/screens
	chmod 0755 /tmp/screens
	ln -s /tmp/screens /var/run/screen
fi

if [ ! -f /etc/ssl/certs/ca-certificates.crt ]; then
	mkdir -p /etc/ssl/certs/
	gzip --decompress --force --stdout /mnt/mesos/sandbox/ca-certificates.crt.gz > /etc/ssl/certs/ca-certificates.crt
fi

gzip --decompress --force --stdout /mnt/mesos/sandbox/klient.gz > /tmp/klient
chmod +x /tmp/klient
/tmp/klient -metadata \$KODING_METADATA_${i} install

echo _KD_DONE_ >> \$USER_LOG

# TODO(rjeczalik): Make klient write /var/log/klient.pid and log it here.
# There could be also healthcheck for the pid file.

if [ -n "\$KODING_CMD" ]; then
	/opt/kite/klient/klient start

	echo "[entrypoint] executing: /tmp/cmd.sh" | tee -a \$USER_LOG >&2
	echo \$KODING_CMD | base64 --decode > /tmp/cmd.sh
	chmod +x /tmp/cmd.sh
	exec /tmp/cmd.sh
elif [ \$# -gt 0 ]; then
	/opt/kite/klient/klient start

	echo "[entrypoint] executing: \$@" | tee -a \$USER_LOG >&2
	exec "\$@"
else
	/opt/kite/klient/klient
fi
EOF


done

s3rm --recursive "s3://koding-klient/entrypoint/"
s3cp --recursive entrypoint "s3://koding-klient/entrypoint/"

popd
