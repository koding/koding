{argv} = require 'optimist'
mongo = require 'mongoskin'

EmailQueue = require './emailqueue'
EmailWorker = require './emailworker'

config = require './' + (argv.c ? 'config-dev')

db = mongo.db (config.mongo ? 'localhost:27017/test') + '?auto_reconnect'

queue = new EmailQueue db

process.on 'uncaughtException', (err)->
  throw err

queue.scheduleTask 'Instant updates from Koding', '*/10 * * * * *', ->
  worker = new EmailWorker config
  worker.on 'SendAttempt', (notification)->
    queue.markAsAttempted notification
  queue.once 'QueueIsEmpty', (length)->
    console.log 'The queue is empty', length
    setTimeout (-> worker.kill()), 500
  queue.forEach (err, notification, user)->
    if err then console.log err
    else if notification? and user?
      {emailFrequency} = user
      emailFrequency = emailFrequency?[notification.event] or emailFrequency?.global or 'instant'
      if emailFrequency is 'never'
        queue.removeItem notification
      else if emailFrequency is 'instant'
        worker.handleNotification notification, user, (err)->
          if err
            console.log err
            queue.next()
          else
            queue.removeItem notification
            queue.next()
    else queue.next()