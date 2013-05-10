module.exports = class BaseDecorator

  constructor:(@datum)->

  decorate:->
    response =
      activity  : @decorateActivity()
      overview  : @decorateOverview()

    return response

  decorateActivity:->
    activity =
      _id         : @datum._id
      type        : @jNameToC()[@datum.name]
      createdAt   : @convertToISO @datum.meta.createdAt
      modifiedAt  : @convertToISO @datum.meta.modifiedAt
      group       : @datum.group
      snapshotIds : [@datum._id]
      snapshot    : JSON.stringify @decorateSnapshot()
      sorts       :
        repliesCount  : @repliesCount()
        likesCount    : @likesCount()
        followerCount : @followerCount()

    return activity

  jNameToC:->
    maps =
      'JStatusUpdate' : 'CStatusActivity'
      'JCodeSnip'     : 'CCodeSnipActivity'
      'JDiscussion'   : 'CDiscussionActivity'

    return maps

  decorateSnapshot:->
    snapshot =
      _id               : @datum._id
      bongo_            :
        constructorName : @datum.name
      slug              : @datum.slug
      slug_             : @datum.slug_
      originId          : @datum.originId
      originType        : @datum.originType
      meta              : @decorateSnapshotMeta()
      body              : @datum.body
      attachments       : @attachments()
      repliesCount      : @repliesCount()
      counts            :
        following       : 0
        followers       : @followerCount()

    snapshot.replies = @datum.relationData.reply  if @datum.relationData.reply
    snapshot.tags    = @datum.relationData.tag    if @datum.relationData.tag

    return snapshot

  decorateSnapshotMeta:->
    snapshotMeta            = @datum.meta
    snapshotMeta.createdAt  = @convertToISO @datum.meta.createdAt
    snapshotMeta.modifiedAt = @convertToISO @datum.meta.modifiedAt

    return snapshotMeta

  attachments:->
    if @datum.attachments is "" then []

  repliesCount:->
    return @extractCountFromRelationData @datum, 'reply'

  likesCount:->
    return @extractCountFromRelationData @datum, 'like'

  followerCount:->
    return @extractCountFromRelationData @datum, 'follower'

  extractCountFromRelationData:(name)->
    return @datum.relationData[name]?.length or 0

  decorateOverview:->
    overview =
      createdAt : [@convertToISO(@datum.meta.createdAt)]
      ids       : [@datum.id]
      type      : @datum.name
      count     : 1

    return overview

  convertToISO: (time)->
    return (new Date(time)).toISOString()
