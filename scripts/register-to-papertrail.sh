#!/bin/bash

if [ ! -f PAPERTRAIL_TOKEN ] || [ ! -f PAPERTRAIL_PORT ]
then
  echo "Papertrail token not provided skipping..."
  exit 0
fi

PAPERTRAIL_URL="https://papertrailapp.com/api/v1/systems"
PAPERTRAIL_PORT=`cat PAPERTRAIL_PORT`
PAPERTRAIL_TOKEN=`cat PAPERTRAIL_TOKEN`

# AWS stores environment vars added via ui in this file. `EB_ENV_NAME` refers to the current
# elasticbeanstalk environment name. It's in format of `koding-<name>`, ie `koding-latest`.
EB_ENV_NAME=`grep -oP 'EB_ENV_NAME=koding-\K([A-Za-z0-9]*)' /opt/elasticbeanstalk/deploy/configuration/containerconfiguration`
PUBLIC_IP=`/opt/aws/bin/ec2-metadata -v | awk '{print $2}'`
PAPERTRAIL_HOST=$EB_ENV_NAME-$PUBLIC_IP

curl -0 -v -X POST $PAPERTRAIL_URL -H "X-Papertrail-Token: $PAPERTRAIL_TOKEN"  \
--data "destination_port=${PAPERTRAIL_PORT}&system[name]=${PAPERTRAIL_HOST}"
