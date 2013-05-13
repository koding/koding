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
    #@addActvityToOverview datum[@groupByName].first, anchorId

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
      datum.relationship.first.createdAt

  decorateOverview:(target, anchorId, createdAt)->
    overview =
      createdAt : [@convertToISO(createdAt)]
      ids       : [anchorId]
      type      : @groupName
      count     : 1

    return overview

  decorateTargetActivity:(datum)->
    return (new TargetActivityDecorator datum, @targetName, @groupByName).decorate()

  decorateGroupActivity:(groupActivity)->
    return (new SingleActivityDecorator groupActivity.first).decorate()

  extractId:(datum)->
    return datum[@targetName].first._id

  # TODO: DRY this
  convertToISO: (time)-> return (new Date(time)).toISOString()
