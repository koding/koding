#! /bin/bash
export GOPATH=`pwd`/../../
export GOBIN=$GOPATH/bin
$GOBIN/rerun  socialapi/workers/api -c vagrant
$GOBIN/rerun  socialapi/workers/topicfeed -c vagrant
