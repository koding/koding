#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

# append datadog api key to its config
echo api_key: $DATADOG_API_KEY >>./.ebextensions/datadog/datadog.conf
