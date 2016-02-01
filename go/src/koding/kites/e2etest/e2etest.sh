#!/bin/bash

# BUG(rjeczalik): -ngrokdebug is required, when it's off ngrok stales on
# process pipes causing the test to hang; ioutil.Discard should be
# plugged somewhere to fix this

# ngrok v1 authtoken, see ./ngrokProxy
export TEST_NGROKTOKEN=${TEST_NGROKTOKEN:-}

# aws creds with access to dev.koding.io Route53 hosted zone
export TEST_ACCESSKEY=${TEST_ACCESSKEY:-}
export TEST_SECRETKEY=${TEST_SECRETKEY:-}

# NOTE(rjeczalik): -noclean is used to keep DNS records, sometimes
# handy for deelopment when AWS is utterly slow.
go test -v koding/kites/e2etest -- -debug -ngrokdebug -noclean

# For more options see
#
#   use go test -v koding/kites/e2etest -- -help
#
