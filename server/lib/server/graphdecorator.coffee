module.exports = class GraphDecorator

  @decorateToCacheObject:(data, callback)->
    cacheObject = []
    for datum in data
      if datum.name == "JStatusUpdate"
        localObject = {}
        localObject.modifiedAt = datum.meta.modifiedAt
        localObject["type"]       = "CStatusActivity"
        localObject["_id"]        = datum.id
        localObject["createdAt"]  = datum.meta.createdAt
        localObject["originId"]   = datum.originId
        localObject["originType"] = datum.originType

        console.log datum
        snapshot = {}
        snapshot.bongo_           = { constructorName : "JStatusUpdate" }
        snapshot.slug             = datum.slug
        snapshot.slug_            = datum.slug_
        snapshot.originId         = datum.originId
        snapshot.originType       = datum.originType
        snapshot.meta             = datum.meta
        snapshot.body             = datum.body
        snapshot.attachments      = datum.attachments
        snapshot._id              = datum._id
        snapshot.repliesCount     = datum.relationData.reply?.length? or 0
        snapshot.replies          = datum.relationData.reply? or null
        snapshot.tags             = datum.relationData.tag? or null
        snapshot.counts           = {}
        snapshot.counts.following = 0
        snapshot.counts.followers = datum.relationData.follower?.length or 0

        localObject["snapshot"] = JSON.stringify( snapshot )

        cacheObject.push localObject
    callback cacheObject