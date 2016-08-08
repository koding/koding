#!/bin/bash

# This script is a hack for glide update.
#
# We use a forked sources for Terraform, in which
# we make certain error types being non-retryable.
#
# We should instead use vanilla Terraform and configure
# it to behave as we require. Or extend it and ditto.
#
# We use a forked sources for gorm, since ./run buildservices
# relies on behaviour of that specific version, otherwise
# building services fails with a lot of pq errors.
# This should be fixed.
#
# TODO(rjeczalik): remove this script

set -euo pipefail

GOPATH=$(git rev-parse --show-toplevel)/go

pushd "$GOPATH/src"

[[ ${1:-} != "-k" ]] && { rm -rf vendor; glide cc; }

glide update --update-vendored --strip-vcs || true

rm -rf vendor/github.com/hashicorp/terraform
git clone git@github.com:koding/terraform vendor/github.com/hashicorp/terraform
rm -rf vendor/github.com/hashicorp/terraform/.git

rm -rf vendor/github.com/jinzhu/gorm
git clone git@github.com:koding/gorm vendor/github.com/jinzhu/gorm
rm -rf vendor/github.com/jinzhu/gorm/.git

popd

