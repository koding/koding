#!/bin/bash

SCRIPT=/tmp/mongocmd.sh

echo "mongo localhost/koding --quiet --eval=\"print(db.jGroups.count({slug:'guests'}))\"" > $SCRIPT

COUNT=$(bash $SCRIPT)

DIR=$(cd "$(dirname "$0")"; pwd)

if [ $COUNT -lt 1 ]; then
  echo "Downloading the mongodump..."
  rm -r /tmp/dump.zip /tmp/dump
  curl https://s3.amazonaws.com/koding-vagrant/mongo/dump.zip > /tmp/dump.zip
  unzip /tmp/dump.zip -d/tmp
  echo "Running the import script"
  mongorestore -hlocalhost -dkoding /tmp/dump/koding
else
  echo "Not running the import script"
fi
