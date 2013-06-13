SOURCE_MONGO_HOST=web-prod.in.koding.com
SOURCE_MONGO_USER=PROD-koding
SOURCE_MONGO_PASS=34W4BXx595ib3J72k5Mh
SOURCE_MONGO_DB=beta_koding
SOURCE_MONGO_CONN=$SOURCE_MONGO_HOST/$SOURCE_MONGO_DB

TARGET_MONGO_HOST=kmongodb1.in.koding.com
TARGET_MONGO_USER=dev
TARGET_MONGO_PASS=k9lc4G1k32nyD72
TARGET_MONGO_DB=koding
TARGET_MONGO_CONN=$TARGET_MONGO_HOST/$TARGET_MONGO_DB

# take a dump of the current state
# TODO: uncomment when the time comes:
mongodump -h$SOURCE_MONGO_HOST -u$SOURCE_MONGO_USER -p$SOURCE_MONGO_PASS -d$SOURCE_MONGO_DB
# disable registrations:
# TODO: uncomment when the time comes:
mongo $SOURCE_MONGO_CONN -u$SOURCE_MONGO_USER -p$SOURCE_MONGO_PASS --eval="db.jRegistrationPreferences.update({},{isRegistrationEnabled:true});"


echo "mongo $TARGET_MONGO_CONN -u$TARGET_MONGO_USER -p$TARGET_MONGO_PASS --eval \"db.dropDatabase()\""
mongo $TARGET_MONGO_CONN -u$TARGET_MONGO_USER -p$TARGET_MONGO_PASS --eval "db.dropDatabase()"

mongorestore ./dump/beta_koding -h$TARGET_MONGO_HOST -u$TARGET_MONGO_USER -p$TARGET_MONGO_PASS -d$TARGET_MONGO_DB
# TODO: put the hostname where we'll be doing this (we use local for now.)

mongo $TARGET_MONGO_CONN -u$TARGET_MONGO_USER -p$TARGET_MONGO_PASS migrate-script.js