#!/usr/bin/env bash
MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh

value=false
if which $2 > /dev/null; then
  value=true
fi

output "$1" $BOOLEAN $value
