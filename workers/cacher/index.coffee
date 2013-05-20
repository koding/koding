{argv}   = require 'optimist'
Bongo    = require 'bongo'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")
Broker   = require 'broker'
{extend} = require 'underscore'

{mongo, cacheWorker, mq} = KONFIG

mongo += '?auto_reconnect'

mqOptions = extend {}, mq
# mqOptions.login = cacheWorker.login if cacheWorker?.login?

koding = new Bongo {
  mongo
  root         : __dirname
  mq           : new Broker mqOptions
  resourceName : cacheWorker.queueName
  models       : '../social/lib/social/models'
}

REROUTING_EXCHANGE_OPTIONS = 
  type        : 'fanout'
  autoDelete  : yes

{JActivityCache, CActivity, JName, JSecretName} = koding.models

do ->

  typesToBeCached = [
      'CStatusActivity'
      'CCodeSnipActivity'
      'CFollowerBucketActivity'
      'CNewMemberBucketActivity'
      'CDiscussionActivity'
      'CTutorialActivity'
      'CBlogPostActivity'
      'CInstallerBucketActivity'
    ]

  cachingInProgress = no

  koding.connect ->
    # TODO: this is an ugly hack.  I just want it to work for now :/
    emitter = new (require('events').EventEmitter)
    JActivityCache.on "CachingFinished", -> cachingInProgress = no

    {connection} = koding.mq

    JName.one name:'koding', (err, name)->
      return console.error err if err
      JSecretName.one name:name._id, (err, secretName)->
        return console.error err if err
        routingKey = "cacheWorker.#{secretName.secretName}"
        # notify rerouter
        connection.exchange 'routing-control', REROUTING_EXCHANGE_OPTIONS, (exchange)->
          controlMessage =
            exchange   : 'cacheWorker'
            bindingKey : 'koding'
            routingKey : routingKey
          # we make sure that there is no other rerouter running
          exchange.publish 'auth.leave', controlMessage
          exchange.publish 'auth.join', controlMessage
          exchange.close()

        connection.exchange 'broker', {type:'topic', autoDelete:no}, (exchange)->
          connection.queue '', {exclusive:yes, autoDelete:yes}, (queue)->
            queue.bind exchange, routingKey
            exchange.close()
            queue.on 'queueBindOk', ->
              queue.subscribe (message)->
                message   = JSON.parse koding.mq.cleanPayload message
                payload   = koding.revive message.contents
                payload   = [payload] unless Array.isArray payload
                emitter.emit message.event, payload...

    emitter.on "ActivityIsCreated", (activity)->
      if not cachingInProgress\
         and activity.constructor.name in typesToBeCached
        cachingInProgress = yes
        JActivityCache.init()

    emitter.on "PostIsDeleted", JActivityCache.removeActivity.bind JActivityCache
    emitter.on "PostIsUpdated", (teaser)->
      {teaserId, createdAt} = teaser
      createdAt = (new Date createdAt).getTime()
      JActivityCache.modifyByTeaser {teaserId, createdAt}

    emitter.on "BucketIsUpdated", (bucketOptions)->
      {type, teaserId, createdAt} = bucketOptions
      if type in typesToBeCached
        createdAt = (new Date createdAt).getTime()
        JActivityCache.modifyByTeaser {teaserId, createdAt}

    emitter.on "UserMarkedAsTroll", (userId)->
      JActivityCache.cleanCacheFromActivitiesOfUser(userId)

    console.log "Activity Cache Worker is ready.\n"

    JActivityCache.init()
