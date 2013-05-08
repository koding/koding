module.exports = class GraphDecorator

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

    cacheObjects = []

    for datum in data
      localObject = if singleActivites[datum.name]
        @extractSingleActivity(datum)
      else if bucketActivities[datum.name]
        @extractBucketActivity(datum)
      else
        console.log "graphdecorator: unimplemented parsing of #{datum.name}"

      cacheObjects.push localObject

    callback cacheObjects

  @extractSingleActivity:(datum)->

    localObject =
      _id        : datum.id
      type       : datum.name
      originId   : datum.originId
      originType : datum.originType
      createdAt  : datum.meta.createdAt
      modifiedAt : datum.meta.modifiedAt

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
      repliesCount      : datum.relationData.reply?.length? or 0
      replies           : datum.relationData.reply? or null
      tags              : datum.relationData.tag? or null
      counts            :
        following       : 0
        followers       : datum.relationData.follower?.length or 0

    localObject["snapshot"] = JSON.stringify snapshot

    return localObject

  @extractBucketActivity:(datum)->

    console.log "TODO: parse #{datum.name}"
