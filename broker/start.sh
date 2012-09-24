#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$DIR/rebar compile
erl +A 128 -pa $DIR/apps/*/ebin -pa $DIR/deps/*/ebin -s broker_app \
  -eval "io:format(\"~n~nServer is running~n\")." 