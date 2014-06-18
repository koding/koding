#!/bin/bash
if [[ $(mongo localhost/koding --quiet --eval="print(db.jGroups.count({slug:'guests'}))") -eq 0 ]]; then
  tar jxvf ./install/default-db-dump.tar.bz2 && mongorestore -hlocalhost -dkoding dump/koding && rm -rf ./dump
fi
