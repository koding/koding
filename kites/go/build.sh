#! /bin/bash

export GOPATH=`dirname "$(readlink -f "$0")"`
go get koding/kites/webterm
