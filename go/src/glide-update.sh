#!/bin/bash

set -euo pipefail

GOPATH=$(git rev-parse --show-toplevel)/go

pushd "$GOPATH/src"

rm -rf vendor
glide cc
glide update --strip-vcs || true
rm -rf vendor/github.com/hashicorp/terraform
git clone git@github.com:koding/terraform vendor/github.com/hashicorp/terraform
rm -rf vendor/github.com/hashicorp/terraform/.git

popd

