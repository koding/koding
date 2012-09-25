#!/bin/sh
ORIG_DIR="$( pwd )"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
./rebar compile
cd $ORIG_DIR
case $1 in
	-detached) erl +A 128 -pa $DIR/apps/*/ebin -pa $DIR/deps/*/ebin -s broker_app \
  					-eval "io:format(\"~n~nServer is running~n\")." -detached
  	;;
	*)	erl +A 128 -pa $DIR/apps/*/ebin -pa $DIR/deps/*/ebin -s broker_app \
				  -eval "io:format(\"~n~nServer is running~n\")."
	;;
esac