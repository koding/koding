#!/usr/bin/env bash

MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh

count=`./users.sh | wc -l | tr -d ' '`
output "user count" $NUMBER $count
