#! /bin/bash

services=(
  koding/broker
  koding/rerouting
  koding/kites/kontrol
  koding/kites/kloud
  koding/kites/kloud/kloudctl
  koding/kites/cmd/terraformer
  koding/kites/cmd/tunnelserver
  koding/workers/guestcleanerworker
  koding/go-webserver
  koding/workers/cmd/tunnelproxymanager
  koding/vmwatcher
  koding/workers/janitor
  koding/workers/gatheringestor
  koding/workers/appstoragemigrator
  koding/kites/kloud/cleaners/cmd/cleaner
  koding/kites/kloud/scripts/userdebug
  koding/kites/kloud/scripts/sl
  koding/klient

  github.com/koding/kite/kitectl
  github.com/canthefason/go-watcher
  github.com/mattes/migrate

  socialapi/workers/api
  socialapi/workers/cmd/notification
  socialapi/workers/cmd/pinnedpost
  socialapi/workers/cmd/popularpost
  socialapi/workers/cmd/trollmode
  socialapi/workers/cmd/populartopic
  socialapi/workers/cmd/realtime
  socialapi/workers/cmd/realtime/gatekeeper
  socialapi/workers/cmd/realtime/dispatcher
  socialapi/workers/cmd/topicfeed
  socialapi/workers/cmd/migrator
  socialapi/workers/cmd/sitemap/sitemapfeeder
  socialapi/workers/cmd/sitemap/sitemapgenerator
  socialapi/workers/cmd/sitemap/sitemapinitializer
  socialapi/workers/cmd/algoliaconnector
  socialapi/workers/cmd/algoliaconnector/deletedaccountremover
  socialapi/workers/payment/paymentwebhook
  socialapi/workers/cmd/topicmoderation
  socialapi/workers/cmd/collaboration
  socialapi/workers/cmd/email/activityemail
  socialapi/workers/cmd/email/dailyemail
  socialapi/workers/cmd/email/privatemessageemailfeeder
  socialapi/workers/cmd/email/privatemessageemailsender
  socialapi/workers/cmd/email/emailsender
  socialapi/workers/cmd/team
  socialapi/workers/cmd/integration/webhook
  socialapi/workers/algoliaconnector/tagmigrator
  socialapi/workers/algoliaconnector/contentmigrator
  socialapi/workers/cmd/integration/eventsender
  socialapi/workers/cmd/integration/webhookmiddleware

  github.com/alecthomas/gocyclo
  github.com/remyoudompheng/go-misc/deadcode
  github.com/opennota/check/cmd/varcheck
  github.com/barakmich/go-nyet
)


`which godep` save "${services[@]}"
