#!/bin/bash

cd $(dirname $0)

MOCHA_BIN_FILE="../../node_modules/mocha/bin/mocha"
MOCHA_OPTIONS="--compilers coffee:coffee-script/register --require coffee-script"
TEST_FILES="./**/*.test.coffee"

MOCHA_RUN_CMD="$MOCHA_BIN_FILE $MOCHA_OPTIONS $TEST_FILES"

$MOCHA_RUN_CMD
