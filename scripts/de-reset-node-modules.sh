#!/bin/bash
DIR=$(
	cd $(dirname "${BASH_SOURCE[0]}")
	pwd
)
NODE_MODULES=$DIR/./../node_modules
MATCHES=$(ls "$NODE_MODULES"_koding)

if [ -d $NODE_MODULES ]; then
  for i in $MATCHES; do
  	rm -r $NODE_MODULES/$i 2>/dev/null
  done
fi