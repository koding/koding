module.exports = class BucketActivityDecorator
  _ = require 'underscore'

  SingleActivityDecorator = require './single_bucket_activity'
  TargetActivityDecorator = require './target_activity'

  constructor:(@data)->
    @groups =
      overview : []

  decorate:->
    @groupByAnchorId()
    for id, value of @groups
      jsonSnaphost = JSON.stringify value.snapshot
      @groups[id].snapshot = jsonSnaphost
      @groups[id].type = @bucketName

    @groups.overview = _.sortBy(@groups.overview, (activity)-> activity.createdAt.first)
    return @groups

  groupByAnchorId:->
    for datum in @data
      anchorId = @extractId datum
      if @groups[anchorId]
        @addActivityToGroup datum, anchorId
      else
        @createNewGroup datum

  addActivityToGroup:(datum, anchorId)->
    # TODO: use anchorId
    id = @extractId datum
    @groups[id].snapshot.group.push @decorateGroupActivity datum[@groupByName]
    @updateCreatedAtInOverview @convertToISO(datum.relationship.first.createdAt), anchorId

  updateCreatedAtInOverview:(createdAt, anchorId) ->
    for followers in @groups.overview when followers.ids.first is anchorId
      followers.createdAt.push createdAt

  # not required since for non member buckets, all entries are grouped
  addActvityToOverview:(datum, anchorId)->
    for followers in @groups.overview when followers.ids.first is anchorId
      followers.ids.push datum.id
      followers.createdAt.push datum.meta.createdAt
      followers.count++

  createNewGroup:(datum)->
    id = @extractId datum
    @groups[id] = @decorateTargetActivity datum
    @groups[id].snapshot.group = [@decorateGroupActivity datum[@groupByName]]
    @groups.overview ||= []
    @groups.overview.push @decorateOverview datum[@groupByName].first, id,\
      @convertToISO(datum.relationship.first.createdAt)

  decorateOverview:(target, anchorId, createdAt)->
    overview =
      createdAt : [@convertToISO(createdAt)]
      ids       : [anchorId]
      type      : @bucketName
      count     : 1

    return overview

  decorateTargetActivity:(datum)->
    return (new TargetActivityDecorator datum, @targetName, @groupByName, @activityName).decorate()

  decorateGroupActivity:(groupActivity)->
    return (new SingleActivityDecorator groupActivity.first).decorate()

  extractId:(datum)->
    return datum[@targetName].first._id

  # TODO: DRY this
  convertToISO: (time)-> return time
