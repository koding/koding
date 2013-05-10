module.exports = class TargetActivityDecorator
  constructor:(@datum, @targetName, @groupByName)->
    @target   = @datum[@targetName].first
    @groupBy  = @datum[@groupByName].first

    #console.log this

  decorate:-> @decorateActivity()

  decorateActivity:->
    activity =
      _id        : @target._id
      type       : @bucketName
      createdAt  : @datum.relationship.first.createdAt
      snapshot   : @decorateSnapshot()
      sorts      :
        repliesCount  : 0   # hardcoded since bucket activities don't have these
        likesCount    : 0
        followerCount : 0
      #snapshotIds: @extractSnapshotIds()

  decorateSnapshot:->
    snapshot =
      _id               : @target._id
      meta              : @target.meta
      groupedBy         : "target"
      sourceName        : @target.name
      bongo_            :
        constructorName : @target.name
      slug              : @datum.slug
      event             : "ItemWasAdded"     # TODO: hardcode?
      group             : []
      snapshotIds       : [@target._id]
