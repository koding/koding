#!/bin/bash

set -o errexit

cd $(dirname $0)

NPM_INSTALL=../scripts/install-npm.sh
$NPM_INSTALL -d landing
