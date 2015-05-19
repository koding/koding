#!/usr/bin/env bash
source output.sh

value=false
if which $2 > /dev/null; then
  value=true
fi

output $INSTALLED $1 $BOOLEAN $value
