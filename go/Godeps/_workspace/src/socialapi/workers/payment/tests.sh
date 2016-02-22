#!/usr/bin/env bash

echo "running payment tests"
go test -c socialapi/workers/payment/ && ./payment.test -c $(dirname $0)/../../config/dev.toml -test.v=true

echo "running stripe tests"
go test -c socialapi/workers/payment/stripe/ && ./stripe.test -c $(dirname $0)/../../config/dev.toml -test.v=true

echo "running paypal tests"
go test -c socialapi/workers/payment/paypal/ && ./paypal.test -c $(dirname $0)/../../config/dev.toml -test.v=true

echo "running webhook tests"
go test -c socialapi/workers/payment/paymentwebhook/ && ./paymentwebhook.test -c $(dirname $0)/../../config/dev.toml -test.v=true
