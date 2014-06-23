#!/bin/bash


### PREPARE ###

# docker pull koding/mongo
# docker pull koding/postgres
# docker pull koding/rabbitmq
# docker pull koding/redis
# docker build -t koding/codebase .


### RUN ###

PRJ=/opt/koding       # `pwd`
BLD=./BUILD_DATA        # /BUILD_DATA
CFG=`cat $BLD/BUILD_CONFIG`
RGN=`cat $BLD/BUILD_REGION` 
HST=`cat $BLD/BUILD_HOSTNAME`
PBKEY=$PRJ/certs/test_kontrol_rsa_public.pem
PVKEY=$PRJ/certs/test_kontrol_rsa_private.pem


echo docker run --expose=27017 -d --name=mongo koding/mongo
echo docker run --expose=5432 -d --name=postgres koding/postgres postgres
echo docker run --expose=15672,5672 -d --name=rabbitmq koding/rabbitmq rabbitmq-server
echo docker run --expose=6379 -d --name=redis koding/redis redis-server

echo docker run                -d --name=kontrolDaemon    --entrypoint $PRJ/go/bin/kontroldaemon koding/codebase -c $CFG
echo docker run                -d --name=kontrolApi       --entrypoint $PRJ/go/bin/kontrolapi    koding/codebase -c $CFG
echo docker run --expose=4000  -d --name=kontrol          --entrypoint $PRJ/go/bin/kontrol       koding/codebase -c $CFG
echo docker run --expose=4001  -d --name=proxy            --entrypoint $PRJ/go/bin/reverseproxy  koding/codebase -region $RGN -host $HST -env production
echo docker run                -d --name=rerouting        --entrypoint $PRJ/go/bin/rerouting     koding/codebase -c $CFG
echo docker run --expose=80    -d --name=webserver        --entrypoint node $PRJ/server/index    koding/codebase -c $CFG -p 80 --disable-newrelic
echo docker run --expose=3526  -d --name=sourceMapServer  --entrypoint node                      koding/codebase -c $PRJ/server/lib/source-server $CFG -p 3526
echo docker run                -d --name=authWorker       --entrypoint node                      koding/codebase $PRJ/workers/auth/index -c  $CFG
echo docker run --expose=3030  -d --name=social           --entrypoint node                      koding/codebase $PRJ/workers/social/index -c  $CFG -p 3030 --disable-newrelic --kite-port=13020
echo docker run                -d --name=kloud            --entrypoint $PRJ/go/bin/kloud         koding/codebase -c $CFG -r $RGN -public-key $PBKEY -private-key $PVKEY -kontrol-url "ws://$HST:4000"
echo docker run                -d --name=guestCleaner     --entrypoint node                      koding/codebase $PRJ/workers/guestcleaner/index -c $CFG
echo docker run                -d --name=cronJobs         --entrypoint $PRJ/go/bin/cron          koding/codebase -c $CFG
echo docker run --expose=8008  -d --name=broker           --entrypoint $PRJ/go/bin/broker        koding/codebase -c $CFG
echo docker run                -d --name=emailSender      --entrypoint node                      koding/codebase $PRJ/workers/emailsender/index -c $CFG