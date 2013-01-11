
{argv}         = require 'optimist'
{mongo, email} = require argv.c
{CronJob}      = require 'cron'
Bongo          = require 'bongo'

worker = new Bongo {
  mongo
  root: __dirname
  models: [
    '../social/lib/social/models/emailnotification.coffee'
  ]
}

log = ->
  console.log "[E-MAIL NOTIFIER]", arguments...

log "Koding E-Mail Notification Worker has started with PID #{process.pid}"

job = new CronJob email.notificationCron, ->

  {JEmail} = worker.models
  log "Running..."

  JEmail.someData {status: "queued"}, {email:yes}, {limit:10}, (err, cursor)->
    if err
      log "Could not load email queue"
    else cursor.toArray (err, queue)->
      log 'E-mails found in queue:', queue

job.start()
