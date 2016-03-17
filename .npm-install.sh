#!/bin/bash

set -o errexit

scripts/patch-node-modules.sh

scripts/install-npm.sh -d client
