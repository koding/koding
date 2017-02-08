#!/bin/bash
DIR=$(
	cd $(dirname "${BASH_SOURCE[0]}")
	pwd
)
NODE_MODULES=$DIR/./../node_modules
MATCHES=$(ls "$NODE_MODULES"_koding)

for i in $MATCHES; do
	rm -r $NODE_MODULES/$i 2>/dev/null
	mkdir $NODE_MODULES 2>/dev/null
	cd $NODE_MODULES
	ln -sf ../node_modules_koding/$i $i
done
