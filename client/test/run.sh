#!/bin/bash

if [[ "$BASH_SOURCE" = /* ]]; then
  RUN_SCRIPT=$BASH_SOURCE
else
  RUN_SCRIPT=$(pwd)/$BASH_SOURCE
fi

cd $(dirname $0)

LOG_DIR=$(pwd)/../../.logs
mkdir -p $LOG_DIR

NIGHTWATCH_BIN="../node_modules/.bin/nightwatch"
NIGHTWATCH_CMD="$NIGHTWATCH_BIN --config ../.nightwatch.json $NIGHTWATCH_OPTIONS"

BUILD_DIR=build/lib

REVISION=$(node -e "process.stdout.write(require('../.config.json').rev)")
export REVISION=${REVISION:0:7}

make --quiet compile

function start_selenium_server() {
  RUN_SELENIUM_OUTPUT_HOST="$LOG_DIR/selenium-host.log"
  RUN_SELENIUM_OUTPUT_PARTICIPANT="$LOG_DIR/selenium-participant.log"

  java -jar vendor/selenium-server-standalone.jar \
       -host 0.0.0.0 \
       -port 42420 \
       > $RUN_SELENIUM_OUTPUT_HOST 2>&1 &

  RUN_SELENIUM_SERVER_PID_HOST=$!

  echo "selenium-server (host): pid: $RUN_SELENIUM_SERVER_PID_HOST out: $RUN_SELENIUM_OUTPUT_HOST"

  java -jar vendor/selenium-server-standalone.jar \
       -host 0.0.0.0 \
       -port 42421 \
       > $RUN_SELENIUM_OUTPUT_PARTICIPANT 2>&1 &

  RUN_SELENIUM_SERVER_PID_PARTICIPANT=$!

  echo "selenium-server (participant) pid: $RUN_SELENIUM_SERVER_PID_PARTICIPANT out: $RUN_SELENIUM_OUTPUT_PARTICIPANT"

  echo

  sleep 5
}

function stop_selenium_server() {
  PID_HOST=$RUN_SELENIUM_SERVER_PID_HOST
  PID_PARTICIPANT=$RUN_SELENIUM_SERVER_PID_PARTICIPANT
  ps --pid $PID_HOST &> /dev/null && kill $PID_HOST
  ps --pid $PID_PARTICIPANT &> /dev/null && kill $PID_PARTICIPANT
}

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
  $NIGHTWATCH_CMD --test $TEST_FILE --testcase $TEST_CASE 2>&1 | \
    tee $LOG_DIR/nightwatch-$TEST_GROUP-$TEST_SUITE-$TEST_CASE.log
  return ${PIPESTATUS[0]}
}

function run_test_suite() {
  export TEST_SUITE_HOOK_DIR=$(mktemp -d)
  for TEST_CASE in $(list_test_cases); do
    $RUN_SCRIPT $TEST_GROUP $TEST_SUITE $TEST_CASE
    EXIT_CODE=$?
    [ $EXIT_CODE -ne 0 ] && exit $EXIT_CODE
  done
  exit $EXIT_CODE
}

function run_test_suite_file() {
  FILE=$1
  TEST_SUITE=$(basename -s '.js' $FILE)
  $RUN_SCRIPT $TEST_GROUP $TEST_SUITE
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
    $RUN_SCRIPT ${FILE#$BUILD_DIR/}
  done
}

function cleanup() {
  if [ "$(hostname)" == 'wercker-test-instance' ]; then
    if [ "$EXIT_CODE" -ne 0 ]; then
      mv users.json users-$TEST_GROUP-$$TEST_SUITE-$TEST_CASE.json
    fi
  fi
}

if [ "$1" == "--names" ]; then
  export RUN_MODE_NAMES="true"
  shift
fi

if [ -z "$RUN_MODE_NAMES" ]; then
 if [ $(hostname) != "wercker-test-instance" ]; then
   if [ -z "$RUN_SELENIUM_SERVER_STARTED" ]; then
     trap stop_selenium_server INT
     start_selenium_server
     export RUN_SELENIUM_SERVER_STARTED=1
   fi
 fi
fi

RESERVED_TEST_CASE_NAMES="
before beforeEach \
after afterEach \
beforeTest afterTest \
beforeClass afterClass \
beforeMethod afterMethod \
beforeSuite afterSuite \
beforeGroups afterGroups \
"

export TEST_GROUP=$1
export TEST_SUITE=$2
export TEST_CASE=$3

if [ -n "$TEST_CASE" ]; then
  for NAME in $RESERVED_TEST_CASE_NAMES; do
    [[ "$TEST_CASE" = "$NAME" ]] && exit 0
  done

  if [ -n "$RUN_MODE_NAMES" ]; then
    echo $TEST_GROUP/$TEST_SUITE/$TEST_CASE
    exit 0
  fi

  if [ -n "$IGNORED_TEST_CASES" ]; then
    if echo -e "$IGNORED_TEST_CASES" | grep --quiet $TEST_GROUP/$TEST_SUITE/$TEST_CASE; then
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

EXIT_CODE=$?

if [ $(hostname) != "wercker-test-instance" ]; then
  if [ -n "$RUN_SELENIUM_SERVER_STARTED" ]; then
    stop_selenium_server
  fi
fi

exit $EXIT_CODE
