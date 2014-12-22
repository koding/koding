#!/bin/bash

echo checking for run-away process ...

CPU_THRESHOLD=90

TOPPROCESS=$(top -b -n 1 | head -n 8 | tail -n 1)

PID=`echo $TOPPROCESS | awk '{print $1}'`
LOAD=`echo $TOPPROCESS | awk '{print $9}'`
NAME=`echo $TOPPROCESS | awk '{print $12}'`

# check if CPU_THRESHOLD is lower than LOAD
if [ 0 -eq "$(echo "${LOAD} < ${CPU_THRESHOLD}" | bc)" ] ; then
  kill -9 $PID
  echo system overloading!
  echo Top-most process killed $NAME

  PUBLIC_HOSTNAME=`/opt/aws/bin/ec2-metadata --public-hostname | awk '{print $2}'`
  SSH_LINK="ssh://ec2-user@$PUBLIC_HOSTNAME"
  MESSAGE="I have restarted *$NAME* at <$SSH_LINK|$HOSTNAME> with *PID:$PID* because of extensive *(% $LOAD) CPU* usage."

  PAYLOAD="payload={\"channel\": \"#_devops\", \"username\": \"assassin\", \"text\": \"$MESSAGE\", \"icon_emoji\": \":ghost:\"}"
  curl -X POST --data-urlencode "$PAYLOAD" https://hooks.slack.com/services/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

else
 echo
 echo no run-aways.
 echo max load $LOAD process $NAME
fi
exit 0
