#!/usr/bin/env bash

#  make relative paths work.
cd $(dirname $0)/..

BIN_DIR=${BIN_DIR:-/usr/local/bin}

go build -o $BIN_DIR/asgd ./cmd/asgd

cp ./init.d/asgd /etc/init.d
chkconfig --add asgd
service asgd start
