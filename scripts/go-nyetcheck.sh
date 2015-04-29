#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

if [[ -z "$GOFILES" ]]; then
    GOFILES=./go/src/socialapi/...
fi

./go/bin/go-nyet $GOFILES
