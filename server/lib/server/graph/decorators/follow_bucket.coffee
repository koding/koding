BucketActivityDecorator = require './bucket_activity'

module.exports = class FollowBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @bucketName  = 'CFollowerBucketActivity'
    @targetName  = 'follower'
    @groupByName = 'follower'

    super @data
