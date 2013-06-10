module.exports = class target_activityDecorator
  constructor:(@datum, @targetName, @groupByName, @activityName)->
    @target   = @datum[@targetName].first
    @groupBy  = @datum[@groupByName].first

  decorate:-> @decorateActivity()

  decorateActivity:->
    activity =
      _id         : @target._id
      type        : @bucketName
      createdAt   : @datum.relationship.first.createdAt
      modifedAt   : @datum.relationship.last.createdAt
      snapshot    : @decorateSnapshot()
      snapshotIds : [@target._id]
      sorts       :
        repliesCount  : 0   # hardcoded since bucket activities don't have these
        likesCount    : 0
        followerCount : 0

  decorateSnapshot:->
    snapshot =
      _id               : @target._id
      meta              : @target.meta
      groupedBy         : "target"
      sourceName        : @groupBy.name
      bongo_            :
        constructorName : @activityName
      slug              : @datum.slug
      event             : "ItemWasAdded"     # TODO: hardcode?
      group             : []
      anchor            :
        id                  : @target._id
        constructorName     : @target.name
