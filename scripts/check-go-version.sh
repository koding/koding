#!/bin/bash

VERSION=$(go version 2>/dev/null)
VERSION=${VERSION:13:4}
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f2)

if [[ $MAJOR -lt 1 ]]; then
	MISMATCH=1
elif [[ $MAJOR -eq 1 && $MINOR -lt 7 ]]; then
	MISMATCH=1
fi

if [[ -n $MISMATCH ]]; then
	echo "error: go version must be 1.7.x\n"
	exit 1
fi
