#!/bin/bash

echo "preparing countly"
command -v mongoimport >/dev/null 2>&1 || { echo "mongoimport is required" && exit 1; }

#  make relative paths work.
cd $(dirname $0)

# configuration #1
cp ./config/configextender.js $KONFIG_COUNTLYPATH/configextender.js
cp ./config/api.config.js $KONFIG_COUNTLYPATH/api/config.js
cp ./config/frontend.express.config.js $KONFIG_COUNTLYPATH/frontend/express/config.js
cp ./config/plugins.json $KONFIG_COUNTLYPATH/plugins/plugins.json

# go to countly's folder
pushd $KONFIG_COUNTLYPATH

# configuration #2
cp ./frontend/express/public/javascripts/countly/countly.config.sample.js ./frontend/express/public/javascripts/countly/countly.config.js

# configuration #3
mkdir -p ./frontend/express/public/sdk/web
# TODO(cihangir): we shouldnt use latest SDK and should pin. but sdk lacks our version ATM.
LATEST_SDK="$(npm info countly-sdk-web version)"
npm install countly-sdk-web@$LATEST_SDK
cp -rf ./node_modules/countly-sdk-web/lib/* ./frontend/express/public/sdk/web/

# configuration 4
npm install traverse
npm install -g node-gyp --unsafe-perm
npm install -g grunt-cli
npm install useragent read-last-lines
npm install
grunt dist-all

# configuration #5 - restore default data
pushd ./bin/backup
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection app_crashgroups58bf06bd6cba850047ac9f19 --file app_crashgroups58bf06bd6cba850047ac9f19.json --upsert
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection app_users58bf06bd6cba850047ac9f19 --file app_users58bf06bd6cba850047ac9f19.json --upsert
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection app_viewdata58bf06bd6cba850047ac9f19 --file app_viewdata58bf06bd6cba850047ac9f19.json --upsert
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection apps --file apps.json --upsert
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection jobs --file jobs.json --upsert
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection members --file members.json --upsert
mongoimport --host=$COUNTLY_MONGODB_HOST --port=$COUNTLY_MONGODB_PORT --db $COUNTLY_MONGODB_DB --collection sessions_ --file sessions_.json --upsert
popd

popd
