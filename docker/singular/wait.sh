#!/bin/bash

function check_mongo() {
  local host=$1
  local mongo_ok=$(mongo $host \
                   --quiet \
                   --eval "db.serverStatus().ok == true" 2> /dev/null)

  [[ $? = 0 && "$mongo_ok" = true ]]
}

function wait_mongo() {
  local host="$1"

  [ -z "$host" ] && exit 1

  echo -n 'wait: mongo'

  until check_mongo $host; do
    echo -n '.'
    sleep 10
  done

  echo ' done!'
}

service=$1

case "$service" in
  mongo)
    wait_mongo "$*";;
esac
