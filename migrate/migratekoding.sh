
# take a dump of the current state
# TODO: uncomment when the time comes:
# mongodump -hweb-prod.in.koding.com -uPROD-koding -p34W4BXx595ib3J72k5Mh -dbeta_koding

# disable registrations:
# TODO: uncomment when the time comes:
# mongo web-prod.in.koding.com/beta_koding -uPROD-koding -p34W4BXx595ib3J72k5Mh  --eval="db.jRegistrationPreferencess.update({},{isRegistrationEnabled:true});"

MONGO_CONN=dev:k9lc4G1k32nyD72@kmongodb1.in.koding.com/beta_koding

mongo $MONGO_CONN --eval "db.dropDatabase()"

mongorestore ./dump -hkmongodb1.in.koding.com -udev -pk9lc4G1k32nyD72 -dkoding
# TODO: put the hostname where we'll be doing this (we use local for now.)

mongo $MONGO_CONN migrate-script.js