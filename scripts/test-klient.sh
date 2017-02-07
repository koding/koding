#!/bin/bash

set -euo pipefail

# TODO: missing -race support: https://github.com/koding/koding/issues/9128

go test -v koding/klient/client \
	koding/klient/fs \
	koding/klient/info \
	koding/klient/logfetcher \
	koding/klient/sshkeys \
	koding/klient/storage

go test -v --race koding/klient/machine/...
