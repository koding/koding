#! /bin/bash

export GOPATH=`dirname "$(readlink -f "$0")"`
go get -v koding/kites/webterm
