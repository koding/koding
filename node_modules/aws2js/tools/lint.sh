#!/bin/bash

function lint
{
	output=$(find $1 -name "*.js" -print0 | xargs -0 jslint --plusplus --white --var --goodparts --node | grep -v "is OK." | grep '[^[:space:]]')
	exit=$?
	echo "$output"
	
	if [ $exit -eq 0 ]
	then
		exit 1
	fi
}

lint config
lint lib
lint tests
