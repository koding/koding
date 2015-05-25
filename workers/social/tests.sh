#!/bin/bash
# this file should be called via ./run socialworkertests

# if KONFIG_JSON json env var is not set, exporting it from run file
if [ -z "$KONFIG_JSON" ]; then
  source $(dirname $0)/../../run
  #restroing mongo database
  sh $(dirname $0)/../../scripts/wercker/restore-default-mongo-dump.sh
fi

cd $(dirname $0)

MOCHA_BIN_FILE="../../node_modules/mocha/bin/mocha"
MOCHA_OPTIONS="--compilers coffee:coffee-script/register --require coffee-script --timeout 15000"
TEST_FILES="./**/*.test.coffee"

MOCHA_RUN_CMD="$MOCHA_BIN_FILE $MOCHA_OPTIONS $TEST_FILES"

$MOCHA_RUN_CMD
