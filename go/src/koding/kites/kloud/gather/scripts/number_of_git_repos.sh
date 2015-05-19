#!/usr/bin/env bash

source output.sh
count=`./git_repos.sh | wc -l`
output $COUNT "git repos" $NUMBER $count
