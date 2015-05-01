#!/bin/bash

cd $(dirname $0)

MAX_TRY_COUNT=3
NIGHTWATCH_BIN="../node_modules/.bin/nightwatch --verbose --config ../.nightwatch.json"
BUILD_DIR=build/lib

REVISION=$(node -e "process.stdout.write(require('../.config.json').rev)")
export REVISION=${REVISION:0:7}

run() {
  SUITE=$1
  SUBSUITE=$2

  if [ -z "$SUITE" ]; then
    for i in ./$BUILD_DIR/*;do
      if [ -d "$i" ];then
          if [ "$i" == "./$BUILD_DIR/helpers" ] || [ "$i" == "./$BUILD_DIR/utils" ]; then
            echo "skipping $i"
          else
            echo "running $i test suite"
            command="$NIGHTWATCH_BIN --group $i"

            counter=0
            until $command
            do
              counter=$((counter + 1))
              if [ $counter -eq $MAX_TRY_COUNT ]
              then
                exit 1
              fi
            done
          fi
      fi
    done
  else
    echo "running single test suite: $SUITE $SUBSUITE"

    if [ -z "$SUBSUITE" ]; then
      command="$NIGHTWATCH_BIN --group ./$BUILD_DIR/$SUITE"
    else
      command="$NIGHTWATCH_BIN --group ./$BUILD_DIR/$SUITE/$SUBSUITE.js"
    fi

    counter=0
    until $command
    do
      counter=$((counter + 1))
      if [ $counter -eq $MAX_TRY_COUNT ]
      then
        exit 1
      fi
    done
  fi
}

run $1 $2
