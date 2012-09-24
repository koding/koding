#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rm -rf $DIR/deps
$DIR/rebar clean get-deps compile -C $DIR/rebar.config deps_dir=$DIR/deps
