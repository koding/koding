#!/bin/bash

# Change to your own Koding Repo's Go golder
KODING_REPO_GO="/Users/fatih/Code/koding/go"

(cd ${KODING_REPO_GO} && ./build.sh)

cd $GOBIN

(cd ${KODING_REPO_GO}/src/koding/kites/kloud/localprovisioner && go build)

# Fill the remaining parts
KONTROL_POSTGRES_PASSWORD=kontrolapp201506 \
KONTROL_STORAGE=postgres \
KONTROL_POSTGRES_USERNAME=kontrolapp201506 \
KONTROL_POSTGRES_DBNAME=social \
KONTROL_POSTGRES_HOST=192.168.59.103 \
KLOUD_MONGODB_URL=192.168.59.103:27017/koding \
KLOUD_ACCESSKEY="" \
KLOUD_SECRETKEY="" \
KLOUD_TESTACCOUNT_ACCESSKEY="" \
KLOUD_TESTACCOUNT_SECRETKEY="" \
KLOUD_TESTACCOUNT_SLUSERNAME="" \
KLOUD_TESTACCOUNT_SLAPIKEY="" \
KLOUD_USER_PUBLICKEY="" \
KLOUD_USER_PRIVATEKEY="" \
TERRAFORMER_KEY="" \
TERRAFORMER_SECRET="" \
${KODING_REPO_GO}/src/koding/kites/kloud/localprovisioner/localprovisioner

cd ${KODING_REPO_GO}/src/koding/kites/kloud/localprovisioner

