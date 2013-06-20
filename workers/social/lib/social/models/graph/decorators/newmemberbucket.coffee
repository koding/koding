BucketActivityDecorator = require './bucketactivity'

module.exports = class NewMemberBucketDecorator extends BucketActivityDecorator
  _ = require 'underscore'

  constructor:(@data)->
    @activityName  = 'CNewMemberBucketActivity'
    @bucketName    = 'CNewMemberBucket'
    @overview      = {createdAt:[], ids:[], type:@activityName, count:1}
    @overviewIndex = {}

  decorate:->
    return {overview:[]}  if @data.length is 0

    members  = {}
    overview = []

    data = _.sortBy @data, (member)-> member.meta.createdAt
    data = data.reverse()

    for member in data
      id = member.id
      generatedMember = {}
      generatedMember.modifiedAt = member.meta.createdAt
      generatedMember.createdAt  = member.meta.createdAt
      generatedMember.type       = @activityName
      generatedMember._id        = id
      snapshot = @generateSnapshot member
      generatedMember.snapshot   = JSON.stringify snapshot
      generatedMember.ids        = [id]
      generatedMember.sorts      = {repliesCount: 0, likesCount: 0, followerCount: 0}
      members[id] =  generatedMember
      @addToOverview(member)

    members.overview = [@overview]

    return members

  addToOverview:(member)->
    @overview.count++

    return  if @overview.count > 5

    @overview.createdAt.unshift member.meta.createdAt
    @overview.ids.unshift member.id

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
