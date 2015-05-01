#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

if [[ -z "$GOFILES" ]]; then
    GOFILES=./go/src/socialapi/*/**/**
fi

found=""
for i in $(ls -d $GOFILES);
do
    if [ -d $i ]; then
        v=$(./go/bin/deadcode $i 2>&1)
        if [ -n "$v" ]; then
            #log it
            ./go/bin/deadcode $i
            found="found"
        fi
    fi
done;
if [[ -n "$found" ]]; then exit 1; fi
