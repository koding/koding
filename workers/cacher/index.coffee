{argv}   = require 'optimist'
Bongo    = require 'bongo'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")
Broker   = require 'broker'
{extend} = require 'underscore'

{mongo, social, mq} = KONFIG

mqOptions = extend {}, mq
mqOptions.login = cacheWorker.login if cacheWorker?.login?

koding = new Bongo {
  mongo
  root         : __dirname
  mq           : new Broker mqOptions
  resourceName : social.queueName
  models       : [
    '../social/lib/social/models/activity/cache.coffee'
    '../social/lib/social/models/activity/index.coffee'
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

  cachingInProcess = no

  # koding.mq
  koding.connect ->

    JActivityCache.on "CachingFinished", -> cachingInProcess = no

    CActivity.addGlobalListener "ActivityIsCreated", (activity)->
      console.log "ever here", activity.constructor.name
      if not cachingInProcess and activity.constructor.name in typesToBeCached
        cachingInProcess = yes
        JActivityCache.init()

    CActivity.addGlobalListener "post-updated", (teaser)->
      JActivityCache.modifyByTeaser teaser

    CActivity.addGlobalListener "BucketIsUpdated", (activity, bucket)->
      console.log bucket.constructor.name, "is being updated"
      if activity.constructor.name in typesToBeCached
        JActivityCache.modifyByTeaser bucket

    console.log "\"feed-new\" event for Activity Caching is bound."
    console.log "\"post-updated\" event for Activity Caching is bound."


