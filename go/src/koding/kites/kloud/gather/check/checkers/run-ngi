#!/usr/bin/env bash

MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh
count=`./git_repos.sh | wc -l`

output "no. git repos" $NUMBER $count
