#!/bin/sh
ORIG_DIR=$( pwd )
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rm -rf $DIR/deps
cd $DIR
$DIR/rebar clean get-deps compile