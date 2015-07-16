#!/usr/bin/env bash

go test -c

./janitor.test -c ../../../socialapi/config/test.toml -test.v=true
RESULT=$?

rm janitor.test

exit $RESULT
