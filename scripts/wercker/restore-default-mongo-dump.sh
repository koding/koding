#!/bin/bash

ROOT=$(dirname $0)/../..
SOCIAL_API_CONFIG_PATH=$ROOT/go/src/socialapi/config/dev.toml
DEFAULT_DB_DUMP=$ROOT/install/docker-mongo/default-db-dump.tar.bz2
PERMISSION_UPDATER=$ROOT/scripts/permission-updater


if [ -z "$WERCKER_MONGODB_HOST" ]; then
  exit
fi

echo '#---> CREATING VANILLA KODING DB @gokmen <---#'

mongo $KONFIG_MONGO --eval "db.dropDatabase()"

tar jxvf $DEFAULT_DB_DUMP
mongorestore -h$WERCKER_MONGODB_HOST -dkoding dump/koding
rm -rf ./dump

echo '#---> UPDATING MONGO DATABASE ACCORDING TO LATEST CHANGES IN CODE (UPDATE PERMISSIONS @chris) <---#'
node $PERMISSION_UPDATER -c $SOCIAL_API_CONFIG_PATH --hard >/dev/null