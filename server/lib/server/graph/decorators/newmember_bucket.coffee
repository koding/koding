BucketActivityDecorator = require './bucket_activity'

module.exports = class NewMemberBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @bucketName          = 'CNewMemberBucket'
    @bucketActivityName  = 'CNewMemberBucketActivity'

  decorate:->
    members = {}
    for member in @data
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

    return members

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