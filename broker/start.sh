#!/bin/sh
erl +A 128 -pa apps/*/ebin -pa deps/*/ebin -s broker_app \
  -eval "io:format(\"~n~nServer is running~n\")." 