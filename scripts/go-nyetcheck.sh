#!/bin/bash
if [[ -z "$GOFILES" ]]; then
    GOFILES=./go/src/socialapi/...
fi

./go/bin/go-nyet $GOFILES
