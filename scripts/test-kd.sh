#!/bin/bash

set -euo pipefail


go test -v koding/klient/remote... \
  koding/klientctl... \
  koding/mountcli... \
  koding/fuseklient/transport...

# Manually testing individual functions because Fuse is having issues
# on wercker currently.
cat << EOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!Partial fuseklient tests run!!!

TODO: Remove -run whitelists once 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOF
go test -v \
  -run TestDir \
  -run TestNode \
  -run TestContentReadWriter \
  -run TestEntry \
  -run TestFakeTransport \
  -run TestErrorTransport \
  -run TestFindWatcher \
  koding/fuseklient...
