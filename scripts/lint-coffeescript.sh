#!/bin/bash

set -o errexit

ROOT_DIR=$(dirname $0)/..
COFFEELINT_BIN="$ROOT_DIR/node_modules/coffeelint/bin/coffeelint"
WORKERS_DIR="$ROOT_DIR/workers"
SERVERS_DIR="$ROOT_DIR/servers"

function runCoffeeLint {
  $COFFEELINT_BIN $1
}

echo 'Linting nodejs web servers directory'
runCoffeeLint $SERVERS_DIR


echo 'Linting workers directory'
runCoffeeLint $WORKERS_DIR
