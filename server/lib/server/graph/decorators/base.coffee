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
      meta              : @decorateSnapshotMeta(@datum)
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
    results = []
    for addition in additions.slice(-3)
      addition.bongo_ = {constructorName : addition.name}
      addition.meta   = @decorateSnapshotMeta addition

      results.push addition

    return results

  decorateSnapshotMeta:(data)->
    snapshotMeta            = data.meta
    snapshotMeta.createdAt  = @convertToISO data.meta.createdAt if snapshotMeta.createdAt
    snapshotMeta.modifiedAt = @convertToISO data.meta.modifiedAt if snapshotMeta.modifiedAt
    snapshotMeta.likes      = parseInt(data.meta.likes, 10) if data.meta.likes

    return snapshotMeta

  attachments:->
    attachments = @datum.attachments
    return if not attachments then [] else attachments

  repliesCount:->
    return @extractCountFromRelationData 'reply'

  likesCount:->
    return @extractCountFromRelationData 'like'

  followerCount:->
    return @extractCountFromRelationData 'follower'

  extractCountFromRelationData:(name)->
    return @datum.relationData[name]?.length or 0

  decorateOverview:->
    overview =
      createdAt : [@convertToISO(@datum.meta.createdAt)]
      ids       : [@datum.id]
      type      : @datum.name
      count     : 1

    return overview

  convertToISO: (time)-> return (new Date(time)).toISOString()
