#!/bin/bash

set -euo pipefail

# TODO: missing -race support: https://koding.atlassian.net/browse/TMS-2158

go test -v koding/klient/client     \
	       koding/klient/fs         \
		   koding/klient/gatherrun  \
		   koding/klient/info       \
		   koding/klient/logfetcher \
		   koding/klient/sshkeys    \
		   koding/klient/storage
