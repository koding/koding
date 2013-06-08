BucketActivityDecorator = require './bucketactivity'

module.exports = class FollowBucketDecorator extends BucketActivityDecorator
  constructor:(@data)->
    @activityName = 'CFollowerBucket'
    @bucketName   = 'CFollowerBucketActivity'
    @targetName   = 'followee'
    @groupByName  = 'follower'

    super @data
