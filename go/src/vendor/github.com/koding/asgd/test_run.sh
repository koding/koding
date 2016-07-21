#! /bin/bash
set -o errexit

export CONFIG_EBENVNAME="test"
export CONFIG_REGION="us-east-1"
export CONFIG_AUTOSCALINGNAME="CONFIG_AUTOSCALINGNAME"
export CONFIG_ACCESSKEYID="CONFIG_ACCESSKEYID"
export CONFIG_SECRETACCESSKEY="CONFIG_SECRETACCESSKEY"
export CONFIG_DEBUG="true"

go test -c && ./asgd.test
rm ./asgd.test
