#!/bin/bash

set -o errexit

$GOPATH/src/socialapi/db/sql/definition/create.sh
$KONFIG_PROJECTROOT/run migrations
$GOBIN/migrate -url $KONFIG_POSTGRES_URL -path $GOPATH/src/socialapi/db/sql/migrations up
