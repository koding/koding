BucketActivityDecorator = require './bucket_activity'

module.exports = class FollowBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @activityName = 'CFollowerBucket'
    @bucketName   = 'CFollowerBucketActivity'
    @targetName   = 'followee'
    @groupByName  = 'follower'

    super @data
