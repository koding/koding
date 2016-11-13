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

echo "executing Koding entrypoint for KODING_METADATA_${i}" >&2

gzip --decompress --force --stdout /mnt/mesos/sandbox/klient.gz > /tmp/klient
chmod +x /tmp/klient
/tmp/klient -metadata \$KODING_METADATA_${i} run

sh -c \$*
EOF


done

s3rm --recursive "s3://koding-klient/entrypoint/"
s3cp --recursive entrypoint "s3://koding-klient/entrypoint/"

popd
