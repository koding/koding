#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

# append datadog api key to its config
echo api_key: $DATADOG_API_KEY >>./.ebextensions/datadog/datadog.conf

# update deployment ssh public and private keys
echo $DEPLOYMENT_KEY_V2_PRIVATE >./deployment/ssh/deployment_rsa
echo $DEPLOYMENT_KEY_V2_PUBLIC >./deployment/ssh/deployment_rsa.pub
