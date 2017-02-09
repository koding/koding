#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

if [[ -z "$GOFILES" ]]; then
	GOFILES=./go/src/socialapi
fi

CMD=$(./go/bin/vet $GOFILES 2>&1 | grep -v "possible formatting directive")
if [[ -n "$CMD" ]]; then
	#log it
	echo $CMD
	exit 1
fi
