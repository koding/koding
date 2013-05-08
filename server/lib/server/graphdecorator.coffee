module.exports = class GraphDecorator

  _ = require 'underscore'

  singleActivites =
    'JStatusUpdate' : true
    'JCodeSnip'     : true
    'JDiscussion'   : true
    'JTutorial'     : true

  bucketActivities =
    'CFollowerBucketActivity'  : true
    'CNewMemberBucketActivity' : true
    'CInstallerBucketActivity' : true

  @decorateToCacheObject:(data, callback)->

    cacheObjects    = {}
    overviewObjects = []

    for datum in data
      if singleActivites[datum.name]
        activity = @extractSingleActivity datum
        overview = @extractSingleActivityOverview datum
      else if bucketActivities[datum.name]
        activity = @extractBucketActivity datum
        overview = @extractBucketActivityOverview datum
      else
        console.log "graphdecorator: don't know about #{datum.name}"

      cacheObjects[activity._id] = activity
      overviewObjects.push overview

    response = @buildResponse cacheObjects, overviewObjects
    callback response

  @extractSingleActivityOverview:(datum)->

    overview =
      createdAt : [datum.meta.createdAt]
      ids       : [datum.id]
      type      : datum.name
      count     : 1

    return overview

  @extractSingleActivity:(datum)->

    repliesCount  = @extractCountFromRelationData datum, 'reply'
    likesCount    = @extractCountFromRelationData datum, 'like'
    followerCount = @extractCountFromRelationData datum, 'follower'

    activity =
      _id        : datum.id
      type       : datum.name
      originId   : datum.originId
      originType : datum.originType
      createdAt  : datum.meta.createdAt
      modifiedAt : datum.meta.modifiedAt
      sorts :
        repliesCount  : repliesCount
        likesCount    : likesCount
        followerCount : followerCount

    snapshot =
      _id               : datum._id
      bongo_            :
        constructorName : datum.name
      slug              : datum.slug
      slug_             : datum.slug_
      originId          : datum.originId
      originType        : datum.originType
      meta              : datum.meta
      body              : datum.body
      attachments       : datum.attachments
      repliesCount      : repliesCount
      replies           : datum.relationData.reply? or null
      tags              : datum.relationData.tag? or null
      counts            :
        following       : 0
        followers       : followerCount

    activity["snapshot"] = JSON.stringify snapshot

    return activity

  @extractCountFromRelationData:(datum, name)->
    datum.relationData[name]?.length or 0

  @extractBucketActivity:(datum)->
    console.log "TODO: parse activity of #{datum.name}"

  @extractBucketActivityOverview:(datum)->
    console.log "TODO: parse overview of #{datum.name}"

  @buildResponse:(cacheObjects, overviewObjects)->

    overviewObjects = @sortByTime overviewObjects
    from            = _.first(overviewObjects).createdAt[0]
    to              = _.last(overviewObjects).createdAt[0]

    response =
      activities : cacheObjects
      from       : from
      to         : to
      overview   : overviewObjects

    return response

  @sortByTime:(overviewObjects)->
    _.sortBy overviewObjects, (overview)-> overview.createdAt
