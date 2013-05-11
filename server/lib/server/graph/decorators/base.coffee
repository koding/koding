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
      #"hede1"         : 'CFollowerBucketActivity'
      #"hede2"         : 'CNewMemberBucketActivity'
      'JDiscussion'   : 'CDiscussionActivity'
      #"hede2"         : 'CInstallerBucketActivity'
      'JTutorial'     : 'CTutorialActivity'
      'JBlogPost'     : 'CBlogPostActivity'

    return maps

    return maps

  decorateSnapshot:->
    snapshot =
      _id               : @datum._id
      bongo_            :
        constructorName : @datum.name
      slug              : @datum.slug
      title             : @datum.title
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

    if @datum.relationData.reply
      snapshot.replies = @decorateAdditions @datum.relationData.reply

    if @datum.relationData.tag
      snapshot.tags = @decorateAdditions @datum.relationData.tag

    return snapshot

  decorateAdditions:(additions)->
    for addition in additions
      addition.bongo = {constructorName : addition.name}

    return additions

  decorateSnapshotMeta:->
    snapshotMeta            = @datum.meta
    snapshotMeta.createdAt  = @convertToISO @datum.meta.createdAt
    snapshotMeta.modifiedAt = @convertToISO @datum.meta.modifiedAt
    snapshotMeta.likes      = parseInt(@datum.meta.likes, 10) if @datum.meta.likes

    return snapshotMeta

  attachments:->
    if @datum.attachments is "" then []

  repliesCount:->
    return @extractCountFromRelationData @datum, 'reply'

  likesCount:->
    return @extractCountFromRelationData @datum, 'like'

  followerCount:->
    return @extractCountFromRelationData @datum, 'follower'

  extractCountFromRelationData:(data, name)->
    return data.relationData[name]?.length or 0

  decorateOverview:->
    overview =
      createdAt : [@convertToISO(@datum.meta.createdAt)]
      ids       : [@datum.id]
      type      : @datum.name
      count     : 1

    return overview

  convertToISO: (time)-> return (new Date(time)).toISOString()
