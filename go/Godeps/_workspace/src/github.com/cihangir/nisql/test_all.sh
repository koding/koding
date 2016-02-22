#!/bin/sh
set -e

echo "Testing against postgres"
export NISQL_TEST_DSN="user=nisqltest password=nisqltest dbname=nisqltest sslmode=disable"
export NISQL_TEST_DIALECT=postgres
go test -cover ./...
