#!/usr/bin/env bash

go test -c

./gatheringestor.test -c ../../../socialapi/config/test.toml -test.v=true
RESULT=$?

rm gatheringestor.test

exit $RESULT
