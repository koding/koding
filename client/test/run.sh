#!/bin/bash

cd $(dirname $0)

NIGHTWATCH_BIN="../node_modules/.bin/nightwatch"
NIGHTWATCH_OPTIONS="$NIGHTWATCH_OPTIONS --config ../.nightwatch.json"
NIGHTWATCH_CMD="$NIGHTWATCH_BIN $NIGHTWATCH_OPTIONS"

BUILD_DIR=build/lib

REVISION=$(node -e "process.stdout.write(require('../.config.json').rev)")
export REVISION=${REVISION:0:7}

make compile

function get_test_group_path() {
  echo $BUILD_DIR/$TEST_GROUP
}

function get_test_suite_path() {
  echo $(get_test_group_path)/$TEST_SUITE.js
}

function run_test_suite() {
  TEST_FILE=$(get_test_suite_path $TEST_GROUP $TEST_SUITE)
  $NIGHTWATCH_CMD --test $TEST_FILE $*
}

function run_test_group() {
  $NIGHTWATCH_CMD --group $(get_test_group_path)
}

function run_all_test_groups() {
  find $BUILD_DIR/ -name '*.js' \
       ! -path "$BUILD_DIR/helpers/*" \
       ! -path "$BUILD_DIR/utils/*" \
       -exec $NIGHTWATCH_CMD --group {} \;
}

function finish() {
  CODE=$1

  if [ "$(hostname)" == 'wercker-test-instance' ]; then
    if [ $CODE -ne 0 ]; then
      mv users.json users-$1-$2.json
    fi
  fi

  exit $CODE
}

TEST_GROUP=$1
TEST_SUITE=$2
TEST_CASE=$3

if [ -n "$TEST_CASE" ]; then
  run_test_suite --testcase $TEST_CASE
elif [ -n "$TEST_SUITE" ]; then
  run_test_suite
elif [ -n "$TEST_GROUP" ]; then
  run_test_group
else
  run_all_test_groups
fi

finish $!
