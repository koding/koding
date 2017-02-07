#!/bin/bash

if ! which supervisord >/dev/null 2>&1; then
	echo 'error: supervisord is not found'
	echo '$ pip install supervisor'
	echo 'http://supervisord.org/installing.html#installing-via-pip'
	exit 255
fi

while IFS=".", read MAJOR MINOR REVISION; do
	if [[ $MAJOR -eq 3 && $MINOR -ge 2 ]]; then
		exit 0
	else
		echo 'error: supervisord version must be 3.2.x'
		exit 1
	fi
done < <(supervisord --version)
