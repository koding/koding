{argv}    = require 'optimist'
Bongo     = require 'bongo'
{CronJob} = require 'cron'

{mongo, amqp, guests} = require argv.c

error =(err)->
  err = message: err if 'string' is typeof err
  console.log 'there was an error'
  console.error err
  console.trace()

message = console.log

worker = new Bongo {
  mongo
  root: __dirname
  models: [
    '../social/lib/social/models/guest.coffee'
  ]
}

message "guest cleanup worker is started."

job = new CronJob guests.cleanupCron, ->
  {JGuest} = worker.models
  JGuest.someData {status: 'needs cleanup'}, {guestId:1}, {limit: guests?.batchSize}, (err, cursor)->
    cursor.each (err, guest)->
      if err
        error err
      else unless guest?
        #message 'no guests to clean up after...'
      else
        message 'need to cleanup after guest', guest.guestId
        JGuest.update guest, {$set: status: 'pristine'}, (err)->
          if err
            error err
          else
            message 'guest', guest.guestId, 'has been reset.'

job.start()