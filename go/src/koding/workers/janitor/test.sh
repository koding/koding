#!/usr/bin/env bash

go test -c

./janitor.test -c ../../../socialapi/config/dev.toml -test.v=true
RESULT=$?

rm janitor.test

exit $RESULT
