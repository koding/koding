#!/usr/bin/env bash

source output.sh

count=`./users.sh | wc -l | tr -d ' '`
output $COUNT "users" $NUMBER $count
