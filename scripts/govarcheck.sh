#!/bin/bash
if [[ -z "$GOPACKAGES" ]]; then
    GOPACKAGES=socialapi/...
fi

v=$(./go/bin/varcheck $GOPACKAGES 2>&1)
if [ -n "$v" ]; then
    #log it
    echo $v
    exit 1
fi
