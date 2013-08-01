module.exports = class BaseDecorator
  constructor:(@data)->
    @datum = @data.data
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
      snapshot    : JSON.stringify @data
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
      'JTutorial'     : 'CTutorialActivity'
      'JBlogPost'     : 'CBlogPostActivity'

    return maps

  repliesCount:->
    return @extractCountFromRelationData 'reply'

  opinionsCount:->
    return @extractCountFromRelationData 'opinion'

  likesCount:->
    return @extractCountFromRelationData 'like'

  followerCount:->
    return @extractCountFromRelationData 'follower'

  extractCountFromRelationData:(name)->
    return @datum[name]?.length or 0

  decorateOverview:->
    overview =
      createdAt : [@convertToISO(@datum.meta.createdAt)]
      ids       : [@datum.id]
      type      : @datum.name
      count     : 1

    return overview

  convertToISO: (time)-> return time.toJSON()
