#!/usr/bin/env bash
MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh

DDOS=`grep 'send(crazy, 0, $size, sockaddr_in($port, $iaddr));' -r /home/ 2> /dev/null | wc -l`

FOUND=false
if [ $DDOS -gt 0 ]
then
  FOUND=true
fi

output "ddos script" $BOOLEAN $FOUND
