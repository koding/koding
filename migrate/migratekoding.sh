
# take a dump of the current state
# TODO: uncomment when the time comes:
# mongodump -hweb-prod.in.koding.com -uPROD-koding -p34W4BXx595ib3J72k5Mh -dbeta_koding

# disable registrations:
# TODO: uncomment when the time comes:
# mongo web-prod.in.koding.com/beta_koding -uPROD-koding -p34W4BXx595ib3J72k5Mh  --eval="db.jRegistrationPreferencess.update({},{isRegistrationEnabled:true});"


mongo beta_koding --eval "db.dropDatabase()"
# TODO: uncomment when the time comes:
mongorestore ./dump # TODO: put the hostname where we'll be doing this (we use local for now.)

mongo localhost/beta_koding migrate-script.js