#!/bin/bash

set -o errexit

pushd $(dirname $0)

touch node_modules/.npm-install.timestamp
