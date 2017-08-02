#!/bin/bash

VERSION=$(node --version | sed -e 's/^v//')

while IFS=".", read MAJOR MINOR REVISION; do
	MISMATCH=1
	if [[ $MAJOR -ge 6 ]]; then
		MISMATCH=
	fi
done < <(echo $VERSION)

if [[ -n "$MISMATCH" ]]; then
	echo "error: node version must be > 6"
	exit 1
fi
