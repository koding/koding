#!/bin/bash

set -o errexit

cd $(dirname $0)

pushd landing
npm install
popd
