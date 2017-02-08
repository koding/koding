#!/bin/bash

PATCHES=$(ls patches)
PATCHED=$(less node_modules/.patched 2>/dev/null)

for i in $PATCHES; do
	if ! [[ $PATCHED =~ $i ]]; then
		patch -N -p1 <patches/$i
		echo $i >>node_modules/.patched
	fi
done
