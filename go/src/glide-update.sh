#!/bin/bash

# This script is a hack for glide update.
#
# We use a forked sources for Terraform, in which
# we make certain error types being non-retryable.
#
# We should instead use vanilla Terraform and configure
# it to behave as we require. Or extend it and ditto.
#
# TODO(rjeczalik): remove this script

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

