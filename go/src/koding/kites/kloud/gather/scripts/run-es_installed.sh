#!/usr/bin/env bash
MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh

FOUND=false
if [ -d "/usr/share/elasticsearch" ]; then
  FOUND=true
fi

output "es installed" $BOOLEAN $FOUND
