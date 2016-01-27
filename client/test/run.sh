#!/bin/bash

cd $(dirname $0)

NIGHTWATCH_BIN="../node_modules/.bin/nightwatch"
NIGHTWATCH_CMD="$NIGHTWATCH_BIN --config ../.nightwatch.json $NIGHTWATCH_OPTIONS"

BUILD_DIR=build/lib

REVISION=$(node -e "process.stdout.write(require('../.config.json').rev)")
export REVISION=${REVISION:0:7}

make --quiet compile

function get_test_group_path() {
  echo $BUILD_DIR/$TEST_GROUP
}

function get_test_suite_path() {
  echo $(get_test_group_path)/$TEST_SUITE.js
}

function list_test_cases() {
  TEST_FILE=$(get_test_suite_path $TEST_GROUP $TEST_SUITE)
  node -p "Object.keys(require('./`get_test_suite_path`')).join('\n')"
}

function run_test_case() {
  TEST_FILE=$(get_test_suite_path $TEST_GROUP $TEST_SUITE)
  $NIGHTWATCH_CMD --test $TEST_FILE --testcase $TEST_CASE
}

function run_test_suite() {
  for TEST_CASE in $(list_test_cases); do
    $BASH_SOURCE $TEST_GROUP $TEST_SUITE $TEST_CASE
  done
}

function run_test_suite_file() {
  FILE=$1
  TEST_SUITE=$(basename -s '.js' $FILE)
  $BASH_SOURCE $TEST_GROUP $TEST_SUITE
}

function run_test_group() {
  for FILE in $(find $(get_test_group_path) -name '*.js'); do
    run_test_suite_file $FILE
  done
}

function run_all_test_groups() {
  for FILE in $(find $BUILD_DIR -mindepth 1 -maxdepth 1 -type d \
       ! -path "$BUILD_DIR/helpers" \
       ! -path "$BUILD_DIR/utils"); do
    $BASH_SOURCE ${FILE#$BUILD_DIR/}
  done
}

function cleanup() {
  if [ "$(hostname)" == 'wercker-test-instance' ]; then
    if [ "$EXIT_CODE" -ne 0 ]; then
      mv users.json users-$TEST_GROUP-$$TEST_SUITE-$TEST_CASE.json
    fi
  fi
}

TEST_GROUP=$1
TEST_SUITE=$2
TEST_CASE=$3

if [ -n "$TEST_CASE" ]; then
  if [ -n "$IGNORED_TEST_CASES" ]; then
    if echo $IGNORED_TEST_CASES | grep $TEST_GROUP/$TEST_SUITE/$TEST_CASE; then
      exit 0
    fi
  fi
  run_test_case
  EXIT_CODE=$?
  cleanup
  exit $EXIT_CODE
elif [ -n "$TEST_SUITE" ]; then
  run_test_suite
elif [ -n "$TEST_GROUP" ]; then
  run_test_group
else
  run_all_test_groups
fi
