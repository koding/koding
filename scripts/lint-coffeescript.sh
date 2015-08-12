#!/bin/bash

ROOT_DIR=$(dirname $0)/..
COFFEELINT_BIN="$ROOT_DIR/node_modules/coffeelint/bin/coffeelint"
SOCIAL_WORKER_COFFEE_DIR="$ROOT_DIR/workers"
NODE_WEBSERVER_COFFEE_DIR="$ROOT_DIR/servers"

function runCoffeeLint {
  $COFFEELINT_BIN $1
}

echo 'Linting nodejs web servers directory'
runCoffeeLint $NODE_WEBSERVER_COFFEE_DIR
