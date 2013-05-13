BucketActivityDecorator = require './bucket_activity'

module.exports = class FollowBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @bucketName  = 'CFollowerBucketActivity'
    @targetName  = 'followee'
    @groupByName = 'follower'

    super @data
