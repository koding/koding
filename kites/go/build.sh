#! /bin/bash

export GOPATH=$(cd "$(dirname "$0")"; pwd)
go get -v koding/kites/webterm koding/kites/os
