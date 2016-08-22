#!/usr/bin/env bash

echo "running payment tests"
go test -c socialapi/workers/payment/ && ./payment.test -c $(dirname $0)/../../config/dev.toml -test.v=true

echo "running api tests"
go test -c socialapi/workers/payment/api && ./api.test -c $(dirname $0)/../../config/dev.toml -test.v=true

