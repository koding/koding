#!/bin/bash

cd $(dirname $0)

set -o errexit

make configure
make install
make build
