#!/bin/bash

echo checking for run-away process ...

CPU_THRESHOLD=75

TOPPROCESS=$(ps -eo pid -eo pcpu -eo command | sort -k 2 -r | grep -v PID | head -n 1)

PID=`echo $TOPPROCESS | awk '{print $1}'`
LOAD=`echo $TOPPROCESS | awk '{print $2}'`
NAME=`echo $TOPPROCESS | awk '{print $3}'`

# check if CPU_THRESHOLD is lower than LOAD
if [ 0 -eq "$(echo "${LOAD} < ${CPU_THRESHOLD}" | bc)" ] ; then
  kill -9 $PID
  echo system overloading!
  echo Top-most process killed $NAME

  MESSAGE=`echo $TOPPROCESS | awk '{print "I restarted " $3 "  because of extensive (%" $2 ") CPU usage. PID was " $1}'`
  PAYLOAD="payload={\"channel\": \"#_devops\", \"username\": \"assassin\", \"text\": \"$MESSAGE\", \"icon_emoji\": \":ghost:\"}"
  curl -X POST --data-urlencode "$PAYLOAD" https://hooks.slack.com/services/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

else
 echo
 echo no run-aways.
 echo max load $LOAD process $NAME
fi
exit 0
