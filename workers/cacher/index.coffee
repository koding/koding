{argv}   = require 'optimist'
KONFIG   = require argv.c?.trim()
nodePath = require 'path'

Bongo    = require 'bongo'

{mongo, projectRoot} = KONFIG

koding = new Bongo {
  mongo
  models: [
    'workers/social/lib/social/models/activity/cache.coffee'
    'workers/social/lib/social/models/activity/index.coffee'
  ].map (path)-> nodePath.join projectRoot, path
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

  CActivity.on "CachingFinished", -> cachingInProcess = no

  CActivity.on "ActivityIsCreated", (activity)->
    console.log "ever here", activity.constructor.name
    if not cachingInProcess and activity.constructor.name in typesToBeCached
      cachingInProcess = yes
      JActivityCache.init()

  CActivity.on "post-updated", (teaser)->
    JActivityCache.modifyByTeaser teaser

  CActivity.on "BucketIsUpdated", (activity, bucket)->
    console.log bucket.constructor.name, "is being updated"
    if activity.constructor.name in typesToBeCached
      JActivityCache.modifyByTeaser bucket

  console.log "\"feed-new\" event for Activity Caching is bound."
  console.log "\"post-updated\" event for Activity Caching is bound."


