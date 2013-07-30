#!/bin/bash

SCRIPT=/tmp/mongocmd.sh

echo "mongo localhost/koding --quiet --eval=\"print(db.jGroups.count({slug:'guests'}))\"" > $SCRIPT

COUNT=$(bash $SCRIPT)

DIR=$(cd "$(dirname "$0")"; pwd)

if [ $COUNT -lt 1 ]; then
  echo "Running the import script"
  mongorestore -hlocalhost -dkoding $DIR/dump/koding
else
  echo "Not running the import script"
fi
