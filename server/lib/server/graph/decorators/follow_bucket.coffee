BucketActivityDecorator = require './bucket_activity'

module.exports = class FollowBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @bucketName = 'CFollowerBucketActivity'
    super @data

  target:-> 'followee'
  groupBy:-> 'follower'

  decorate:->
    groups = super
    return groups
