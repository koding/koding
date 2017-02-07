#!/bin/bash

VERSION=$(npm --version)

while IFS=".", read MAJOR MINOR REVISION; do
	if [[ $MAJOR -lt 4 ]]; then
		MISMATCH=1
	fi
done < <(echo $VERSION)

if [[ -n "$MISMATCH" ]]; then
	echo "error: npm version must be 4"
	exit 1
fi
