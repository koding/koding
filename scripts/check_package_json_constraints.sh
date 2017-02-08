#!/bin/bash

# package json should not have special npm chars
if grep -q '\"^\|\"~\|\"\*' ./package.json; then
	echo "package json has (^,*,~) in it, commit without them."
	exit 1
elif grep -q '\"^\|\"~\|\"\*' ./client/package.json; then
	echo "client package json has (^,*,~) in it, commit without them."
	exit 1
else
	exit 0
fi
