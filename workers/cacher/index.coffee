{argv}   = require 'optimist'
Bongo    = require 'bongo'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")
Broker   = require 'broker'
{extend} = require 'underscore'

{mongo, cacheWorker, mq} = KONFIG

mqOptions = extend {}, mq
mqOptions.login = cacheWorker.login if cacheWorker?.login?

koding = new Bongo {
  mongo
  root         : __dirname
  mq           : new Broker mqOptions
  resourceName : cacheWorker.queueName
  models       : [
    '../social/lib/social/models/activity/cache.coffee'
    '../social/lib/social/models/activity/index.coffee'
    '../social/lib/social/models/messages'
  ]
}

{JActivityCache, CActivity} = koding.models

do ->

  typesToBeCached = [
      'CStatusActivity'
      'CCodeSnipActivity'
      'CFollowerBucketActivity'
      'CNewMemberBucketActivity'
      'CDiscussionActivity'
      'CTutorialActivity'
      'CInstallerBucketActivity'
    ]

  cachingInProgress = no

  # koding.mq
  koding.connect ->
    # TODO: this is an ugly hack.  I just want it to work for now :/
    emitter = new (require('events').EventEmitter)
    JActivityCache.on "CachingFinished", -> cachingInProgress = no

    {connection} = koding.mq

    connection.exchange 'broker', {type:'topic', autoDelete:yes}, (exchange)->
      connection.queue '', {exclusive: yes, autoDelete: yes}, (queue)->
        queue.bind exchange, 'constructor.CActivity.event.#'
        queue.on 'queueBindOk', ->
          queue.subscribe (message, headers, deliveryInfo)->
            eventName = deliveryInfo.routingKey.split('.').pop()
            payload = koding.revive message
            payload = [payload]  unless Array.isArray payload
            emitter.emit eventName, payload...


    emitter.on "ActivityIsCreated", (activity)->
      if not cachingInProgress\
         and activity.constructor.name in typesToBeCached
        cachingInProgress = yes
        JActivityCache.init()

    emitter.on "post-updated", (teaser)->
      JActivityCache.modifyByTeaser teaser

    emitter.on "BucketIsUpdated", (activityType, bucket)->
      if actvityType in typesToBeCached
        JActivityCache.modifyByTeaser bucket

    console.log "Activity Cache Worker is ready."
