#!/bin/sh
ORIG_DIR="$( pwd )"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
./rebar compile
case $1 in
	-detached) erl +A 128 -pa apps/*/ebin -pa deps/*/ebin -s broker_app \
  					-eval "io:format(\"~n~nServer is running~n\")." -detached
  	;;
	*)	erl +A 128 -pa apps/*/ebin -pa deps/*/ebin -s broker_app \
				  -eval "io:format(\"~n~nServer is running~n\")."
	;;
esac
cd $ORIG_DIR