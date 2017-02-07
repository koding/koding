#!/bin/bash

if ! which mongo >/dev/null 2>&1; then
	echo 'error: mongo is not found'
	echo 'https://docs.mongodb.com/manual/installation/'
	exit 255
fi

version=$(mongo --version | head -n1 | awk '{ print $NF; }')

while IFS=".", read major minor revision; do
	major=$(echo $major | sed -e 's/^v//')
	if [[ $major -ge 3 ]]; then
		exit 0
	else
		echo 'error: mongo version must be 3.x'
		exit 1
	fi
done < <(echo $version)
