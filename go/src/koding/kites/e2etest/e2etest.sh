#!/bin/bash

# BUG(rjeczalik): -ngrokdebug is required, when it's off ngrok stales on
# process pipes causing the test to hang; ioutil.Discard should be
# plugged somewhere to fix this

# ngrok v1 authtoken, see ./ngrokProxy
export E2ETEST_NGROKTOKEN=${E2ETEST_NGROKTOKEN:-}

# aws creds with access to dev.koding.io Route53 hosted zone
export E2ETEST_ACCESSKEY=${E2ETEST_ACCESSKEY:-}
export E2ETEST_SECRETKEY=${E2ETEST_SECRETKEY:-}

run=${1:-}

if [[ ! -z "$run" ]]; then
	run="-run $run"
fi

# TODO(rjeczalik): enable after fixing TMS-3077
exit 0

# NOTE(rjeczalik): -noclean is used to keep DNS records, sometimes
# handy for deelopment when AWS is utterly slow.
go test -v koding/kites/e2etest $run -- -debug -ngrokdebug -noclean

# For more options see
#
#   go test -v koding/kites/e2etest -- -help
#
