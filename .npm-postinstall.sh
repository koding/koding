#!/bin/bash

set -o errexit

scripts/reset-node-modules.sh
touch $(dirname $0)/node_modules/.npm-install.timestamp
