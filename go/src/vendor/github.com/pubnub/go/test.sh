#!/usr/bin/env bash

set -e
echo "" > coverage.txt

go version

if [[ $TRAVIS_GO_VERSION == 1.4.3 ]]; then
  go get golang.org/x/tools/cmd/cover
fi

go test -coverprofile=unit_tests.out -covermode=atomic -coverpkg=./messaging ./messaging/

# go test -v -coverprofile=errors_tests.out -covermode=atomic -coverpkg=./messaging \
# ./messaging/tests/ -test.run TestError*

go test -v -coverprofile=integration_tests.out -covermode=atomic -coverpkg=./messaging \
./messaging/tests/ -test.run '^(Test[^(?:Error)].*)'

gocovmerge unit_tests.out integration_tests.out > coverage.txt

rm unit_tests.out integration_tests.out
