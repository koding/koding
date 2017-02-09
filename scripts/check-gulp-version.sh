#!/bin/bash

VERSION=$(npm info gulp version 2>/dev/null)

while IFS=".", read MAJOR MINOR REVISION; do
	if [[ $MAJOR -lt 3 ]]; then
		MISMATCH=1
	elif [[ $MAJOR -eq 3 && $MINOR -lt 9 ]]; then
		MISMATCH=1
	fi
done < <(echo $VERSION)

if [[ -n $MISMATCH ]]; then
	echo 'error: gulp version must be 3.9.x'
	exit 1
fi
