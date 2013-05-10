module.exports = class BucketActivityDecorator
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

    return @groups

  groupByAnchorId:->
    for datum in @data
      id = @extractId datum
      if @groups[id]
        @addFollowerToGroup datum
      else
        @createNewGroup datum

  addFollowerToGroup:(datum)->
    id = @extractId datum
    @groups[id].snapshot.group.push @decorateGroupActivity datum[@groupBy()]

  createNewGroup:(datum)->
    id = @extractId datum
    @groups[id] = @decorateTargetActivity datum
    @groups[id].snapshot.group = [@decorateGroupActivity datum[@groupBy()]]
    @groups.overview = @decorateOverview datum.followee.first

  decorateOverview:(target)->
    overview =
      createdAt : [@convertToISO(target.meta.createdAt)]
      ids       : [target.id]
      type      : @groupName
      count     : 1

    return overview

  decorateTargetActivity:(datum)->
    return (new TargetActivityDecorator datum, @target(), @groupBy()).decorate()

  decorateGroupActivity:(groupActivity)->
    return (new SingleActivityDecorator groupActivity.first).decorate()

  extractId:(datum)->
    return datum[@target()].first._id

  target:->
    console.log 'implement this in child class'

  groupBy:->
    console.log 'implement this in child class'

  # TODO: DRY this
  convertToISO: (time)-> return (new Date(time)).toISOString()
