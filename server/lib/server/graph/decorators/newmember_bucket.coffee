BucketActivityDecorator = require './bucket_activity'

module.exports = class NewMemberBucketDecorator extends BucketActivityDecorator
  _ = require 'underscore'

  constructor:(@data)->
    @activityName  = 'CNewMemberBucketActivity'
    @bucketName    = 'CNewMemberBucket'
    @overview      = {createdAt:[], ids:[], type:"CFollowerBucketActivity", count:1}
    @overviewIndex = {}

  decorate:->
    members  = {}
    overview = []

    data = _.sortBy @data, (member)-> member.meta.createdAt
    data = data.reverse()

    for member in data
      id = member.id
      generatedMember = {}
      generatedMember.modifiedAt = member.meta.cretadAt
      generatedMember.createdAt  = member.meta.cretadAt
      generatedMember.type       = @bucketActivityName
      generatedMember._id        = id
      snapshot = @generateSnapshot member
      generatedMember.snapshot   = snapshot
      generatedMember.ids        = [id]
      generatedMember.sorts      = {repliesCount: 0, likesCount: 0, followerCount: 0}

      members[id] =  generatedMember

      @addToOverview(member)

    members.overview = @overview

    return members

  addToOverview:(member)->
    @overview.createdAt.push member.meta.createdAt
    @overview.ids.push member.id
    @overview.count++

  generateSnapshot:(member)->

    snapshot = {}
    snapshot._id         = member.id
    snapshot.sourceName  = member.name

    bongo = {constructorName : @bucketName}
    snapshot.bongo_      = bongo
    snapshot.meta        = member.meta
    snapshot.group       = []

    anchor =
      bongo_ : { constructorName : "ObjectRef" }
      constructorName : member.name
      id : member.id

    snapshot.anchor      = anchor

    return snapshot