#!/bin/bash

function check_mongo() {
  local MONGO_OK=$(mongo $KONFIG_MONGO \
                   --quiet \
                   --eval "db.serverStatus().ok == true")

  if [[ $? != 0 || "$MONGO_OK" != true ]]; then
    echo "error: mongodb service check failed on $KONFIG_MONGO"
    return 1
  fi

  return 0
}

function check_postgres() {
  pg_isready --host $KONFIG_POSTGRES_HOST \
             --port $KONFIG_POSTGRES_PORT \
             --username $KONFIG_POSTGRES_USERNAME \
             --dbname $KONFIG_POSTGRES_DBNAME \
             --quiet

  if [ $? != 0 ]; then
    echo "error: postgres service check failed on $KONFIG_POSTGRES_HOST:$KONFIG_POSTGRES_PORT"
    return 1
  fi

  return 0
}

function check_rabbitmq() {
  local USER=$KONFIG_MQ_LOGIN:$KONFIG_MQ_PASSWORD
  local HOST=$KONFIG_MQ_HOST:$KONFIG_MQ_APIPORT
  local RESPONSE_CODE=$(curl --silent --output /dev/null --write-out '%{http_code}' --user $USER http://$HOST/api/overview)

  if [[ $? != 0 || $RESPONSE_CODE != 200 ]]; then
    echo "error: rabbitmq service check failed on $KONFIG_MQ_HOST:$KONFIG_MQ_APIPORT"
    return 1
  fi

  return 0
}

function check_redis() {
  local REDIS_PONG=$(redis-cli -h $KONFIG_REDIS_HOST \
            -p $KONFIG_REDIS_PORT \
            ping)

  if [[ $? != 0 || "$REDIS_PONG" != PONG ]]; then
    echo "error: redis service check failed on $KONFIG_REDIS_HOST:$KONFIG_REDIS_PORT"
    return 1
  fi

  return 0
}

function check() {
  local INTERVAL=10 COUNTER=0 TRY_COUNT=6

  until eval "check_$@"; do
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -eq $TRY_COUNT ]; then
      exit 1
    fi
    sleep $INTERVAL
  done
}

check mongo
check postgres
check rabbitmq
check redis

exit 0
